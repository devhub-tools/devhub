defmodule DevhubWeb.Components.QueryDesk.QueryLibrary do
  @moduledoc false
  use DevhubWeb, :live_component

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.Shared
  alias Devhub.Shared.Schemas.Label

  def update(assigns, socket) do
    saved_queries = QueryDesk.list_saved_queries(assigns.organization_user)

    labels = Shared.list_labels(assigns.organization.id)

    assigned_labels = derive_assigned_labels(saved_queries)

    filtered_labels = Enum.filter(assigned_labels, &(&1.name in assigns.label_filter))

    selected_query = Enum.find(saved_queries, &(&1.id == assigns.selected_query_id))

    socket =
      socket
      |> assign(assigns)
      |> assign(
        saved_queries: saved_queries,
        selected_query: selected_query,
        saved_query_changeset: nil,
        filtered_labels: filtered_labels,
        assigned_labels: assigned_labels,
        labels: labels
      )

    if selected_query do
      changeset = SavedQuery.changeset(selected_query, %{})

      socket
      |> assign(saved_query_changeset: changeset)
      |> push_event("load_from_local_storage", %{
        "localStorageKey" => selected_query.id,
        "default" => selected_query.query
      })
      |> ok()
    else
      socket |> push_event("set_query", %{"query" => ""}) |> ok()
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="ml-4">
        <.back navigate={~p"/querydesk/databases/#{@database_id}/query"}>
          Tables
        </.back>
      </div>
      <p class="text-alpha-64 border-alpha-8 border-b px-4 pt-4 pb-1 text-sm">Query library</p>
      <div class="border-alpha-8 border-b p-4">
        <.form
          :let={f}
          for={%{"search" => @search}}
          phx-change="search_saved_queries"
          phx-target={@myself}
        >
          <.input field={f[:search]} type="text" label="Search" phx-debounce phx-target={@myself} />
        </.form>

        <div class="mt-4 flex items-center justify-between">
          <div class="text-alpha-64 flex flex-col text-xs">
            LABEL FILTER
          </div>

          <div class="tooltip tooltip-left">
            <button type="button" phx-click={show_modal("add-label-to-filter")} phx-target={@myself}>
              <.icon name="hero-plus" class="size-4 bg-blue-400" />
            </button>
            <span class="tooltiptext text-nowrap">Add label to filter</span>
          </div>
        </div>

        <div class="flex flex-wrap gap-x-1" data-testid="saved-queries-labels">
          <div
            :for={label <- @filtered_labels}
            class="ring-alpha-8 mt-1 flex w-fit items-center gap-x-1 truncate rounded-full px-2 py-1 text-xs text-gray-600 ring-1 ring-inset"
          >
            <div class="mr-1 h-2 w-2 rounded-full" style={"background-color:#{label.color}"}></div>
            {label.name}
            <button
              phx-click="remove_label_filter"
              phx-value-remove_label={label.name}
              phx-target={@myself}
            >
              <.icon name="hero-x-mark" class="size-3 text-gray-400 hover:text-gray-600" />
            </button>
          </div>
        </div>
      </div>

      <ul class="divide-alpha-8 divide-y" data-testid="saved-queries-list">
        <li
          :for={query <- filter_saved_queries(@saved_queries, @search, @label_filter)}
          class="border-surface-3 group relative cursor-pointer p-4 text-xs hover:bg-alpha-4"
          phx-click="select_query"
          role="button"
          phx-value-id={query.id}
          phx-target={@myself}
        >
          <div class="flex items-center justify-between">
            <p class="truncate">{query.title}</p>
            <.icon :if={query.private} name="hero-eye-slash" class="size-3 text-gray-600" />
          </div>
          <div class="mt-1 truncate text-gray-600">
            {query.query}
          </div>
          <div class="mt-2 flex flex-wrap gap-x-1">
            <.object_label
              :for={label <- query.labels}
              phx-click="add_label_filter"
              phx-value-label_id={label.id}
              phx-target={@myself}
              label={label}
            />
          </div>
        </li>
      </ul>

      <.sidebar
        selected_query={@selected_query}
        saved_query_changeset={@saved_query_changeset}
        variables={@variables}
        myself={@myself}
        user={@user}
        label_search={@label_search}
        assigned_labels={@assigned_labels}
      />

      <.label_filter_modal
        filtered_labels={@filtered_labels}
        assigned_labels={@assigned_labels}
        label_search={@label_search}
        myself={@myself}
      />

      <.label_modal
        :if={@selected_query}
        selected_query={@selected_query}
        labels={@labels}
        label_search={@label_search}
        myself={@myself}
      />
    </div>
    """
  end

  def handle_event("select_query", %{"id" => query_id}, socket) do
    socket
    |> patch_current(%{"query_id" => query_id, "search" => socket.assigns.search})
    |> noreply()
  end

  def handle_event("search_saved_queries", %{"search" => search}, socket) do
    socket
    |> assign(search: search)
    |> noreply()
  end

  def handle_event("search_labels", %{"label_search" => label_search}, socket) do
    socket
    |> assign(label_search: label_search)
    |> noreply()
  end

  def handle_event("update_saved_query", %{"saved_query" => params}, socket) do
    params =
      if socket.assigns.user.id == socket.assigns.selected_query.created_by_user_id do
        Map.take(params, ["title", "private"])
      else
        Map.take(params, ["title"])
      end

    case QueryDesk.update_saved_query(socket.assigns.selected_query, params) do
      {:ok, query} ->
        changeset = SavedQuery.changeset(query, %{})
        socket |> update_saved_queries(query) |> assign(saved_query_changeset: changeset) |> noreply()

      {:error, changeset} ->
        socket |> assign(saved_query_changeset: changeset) |> noreply()
    end
  end

  def handle_event("delete_saved_query", %{"id" => id}, socket) do
    query = Enum.find(socket.assigns.saved_queries, &(&1.id == id))

    case QueryDesk.delete_saved_query(query) do
      {:ok, _query} ->
        socket
        |> assign(saved_query_changeset: nil)
        |> push_event("set_query", %{"query" => ""})
        |> push_patch(to: ~p"/querydesk/databases/#{socket.assigns.database_id}/library")
        |> noreply()

      {:error, _error} ->
        socket |> push_flash(:error, "Failed to delete query.") |> noreply()
    end
  end

  def handle_event("add_existing_label_to_selected_query", %{"label_id" => label_id}, socket) do
    label = Enum.find(socket.assigns.labels, &(&1.id == label_id))
    selected_query = socket.assigns.selected_query

    case Shared.create_object_label(%{
           organization_id: socket.assigns.organization.id,
           label_id: label.id,
           saved_query_id: selected_query.id
         }) do
      {:ok, _object} ->
        selected_query = %{selected_query | labels: [label | selected_query.labels]}

        socket
        |> update_saved_queries(selected_query)
        |> assign(label_search: "")
        |> noreply()

      _error ->
        socket |> push_flash(:error, "Failed to add label to query.") |> noreply()
    end
  end

  def handle_event("add_new_label", %{"label_name" => label_name}, socket) do
    selected_query = socket.assigns.selected_query

    with {:ok, label} <-
           Shared.insert_or_update_label(
             %Label{organization_id: socket.assigns.organization.id},
             %{
               "name" => label_name
             }
           ),
         {:ok, _object} <-
           Shared.create_object_label(%{
             organization_id: socket.assigns.organization.id,
             label_id: label.id,
             saved_query_id: selected_query.id
           }) do
      selected_query = %{selected_query | labels: [label | selected_query.labels]}

      socket
      |> update_saved_queries(selected_query)
      |> assign(
        labels: [label | socket.assigns.labels],
        label_search: ""
      )
      |> noreply()
    else
      _error ->
        {:noreply, socket}
    end
  end

  def handle_event("remove_object_label", %{"label_id" => label_id}, socket) do
    selected_query = socket.assigns.selected_query
    label = Enum.find(socket.assigns.selected_query.labels, &(&1.id == label_id))

    Shared.remove_object_label(label_id: label.id, saved_query_id: selected_query.id)

    labels = List.delete(selected_query.labels, label)
    updated_query = %{selected_query | labels: labels}

    socket |> update_saved_queries(updated_query) |> noreply()
  end

  def handle_event("add_label_filter", %{"label_id" => label_id}, socket) do
    label = Enum.find(socket.assigns.assigned_labels, &(&1.id == label_id))
    label_filter = Enum.join([label.name | socket.assigns.label_filter], ",")
    socket |> patch_current(%{"label_filter" => label_filter}) |> noreply()
  end

  def handle_event("remove_label_filter", %{"remove_label" => label}, socket) do
    label_filter = socket.assigns.label_filter |> List.delete(label) |> Enum.join(",")
    socket |> patch_current(%{"label_filter" => label_filter}) |> noreply()
  end

  defp sidebar(%{selected_query: nil} = assigns) do
    ~H"""
    <div class="bg-surface-1 fixed inset-4 left-auto z-10 w-80 rounded-lg text-sm">
      <p class="text-alpha-64 border-alpha-8 mb-3 border-b p-4 pb-1 text-sm">Select a query</p>
    </div>
    """
  end

  defp sidebar(assigns) do
    variables =
      ~r/\${([^}]+)}/
      |> Regex.scan(assigns.selected_query.query)
      |> Map.new(fn [_full_match, var_name] -> {var_name, assigns.variables[var_name]} end)

    descriptions = extract_variable_descriptions(assigns.selected_query.query)

    assigns = assign(assigns, variables: variables, descriptions: descriptions)

    ~H"""
    <div class="bg-surface-1 fixed top-0 right-0 bottom-0 z-10 m-4 w-80 rounded-lg p-4">
      <div class="flex h-full flex-col justify-between">
        <div>
          <.form
            :let={f}
            for={@saved_query_changeset}
            phx-change="update_saved_query"
            phx-target={@myself}
            autocomplete="off"
          >
            <.input field={f[:title]} type="text" label="Title" phx-debounce />

            <div class="mt-4">
              <.input
                :if={@user.id == @selected_query.created_by_user_id}
                field={f[:private]}
                type="toggle"
                label="Private"
                tooltip="Private queries are only visible to you"
                tooltip_position="bottom"
              />
            </div>
          </.form>

          <div class="mt-4 flex items-center justify-between">
            <div class="text-alpha-64 flex flex-col text-xs">
              LABELS
            </div>

            <div class="tooltip tooltip-bottom">
              <button type="button" phx-click={show_modal("add-label")} phx-target={@myself}>
                <.icon name="hero-plus" class="size-4 bg-blue-400" />
              </button>
              <span class="tooltiptext text-nowrap">Add label</span>
            </div>
          </div>

          <div class="flex items-center justify-between">
            <div class="flex flex-wrap gap-x-1">
              <.object_label
                :for={label <- @selected_query.labels}
                label={label}
                phx-click="remove_object_label"
                phx-value-label_id={label.id}
                phx-target={@myself}
                icon="hero-x-mark"
              />
            </div>
          </div>
          <p class="text-alpha-64 border-alpha-8 my-4 border-b pb-1 text-sm">Variables</p>

          <.form
            :let={f}
            for={@variables}
            id={"variables-" <> @selected_query.id}
            phx-hook="PreventSubmit"
            phx-change="update_variables"
            autocomplete="off"
            class="flex flex-col gap-y-4"
          >
            <div :for={{variable, _value} <- @variables} class="flex flex-col gap-y-2">
              <.input field={f[variable]} type="text" label={variable} phx-debounce />
              <span class="text-alpha-64 text-xs">
                {@descriptions[variable]}
              </span>
            </div>
          </.form>
        </div>

        <.button
          type="button"
          phx-click="delete_saved_query"
          phx-value-id={@selected_query.id}
          phx-target={@myself}
          variant="destructive-text"
          data-confirm="Are you sure want to delete this query?"
        >
          Delete
        </.button>
      </div>
    </div>
    """
  end

  defp label_filter_modal(assigns) do
    ~H"""
    <.modal id="add-label-to-filter">
      <span :if={@filtered_labels != []} class="text-alpha-64 flex flex-col text-xs">
        LABEL FILTER
      </span>

      <div class={["flex flex-wrap gap-x-1 pb-2", @filtered_labels != [] && "border-alpha-8 border-b"]}>
        <div
          :for={label <- @filtered_labels}
          class="ring-alpha-8 my-2 flex w-fit items-center gap-x-1 truncate rounded-full px-2 py-1 text-xs text-gray-600 ring-1 ring-inset"
        >
          <div class="m-1 h-2 w-2 rounded-full" style={"background-color:#{label.color}"}></div>
          {label.name}

          <button
            :if={label in @filtered_labels}
            phx-click="remove_label_filter"
            phx-value-remove_label={label.name}
            phx-target={@myself}
          >
            <.icon name="hero-x-mark" class="size-3 text-gray-400 hover:text-gray-600" />
          </button>
        </div>
      </div>

      <div class="mt-4 flex flex-col gap-y-4">
        <.form
          :let={f}
          for={%{"label_search" => @label_search}}
          class="border-alpha-8"
          phx-change="search_labels"
          phx-target={@myself}
          id="label-search-for-filter"
        >
          <.input
            field={f[:label_search]}
            type="text"
            label="Search"
            phx-debounce
            phx-target={@myself}
          />
        </.form>

        <%!-- unselected labels --%>
        <% unselected_labels =
          Enum.filter(
            filter_labels(@assigned_labels, @label_search),
            &(&1 not in @filtered_labels)
          ) %>
        <div class="flex flex-col gap-y-2">
          <span class="text-alpha-64 text-xs">
            LABELS
          </span>
          <span :if={Enum.empty?(unselected_labels)} class="text-alpha-64 text-xs">
            No matching labels
          </span>
          <div class="flex flex-wrap gap-1">
            <div
              :for={label <- unselected_labels}
              class="ring-alpha-8 flex w-fit items-center gap-x-1 truncate rounded-full px-2 py-1 text-xs text-gray-600 ring-1 ring-inset hover:bg-alpha-4"
            >
              <button
                :if={label not in @filtered_labels}
                phx-click="add_label_filter"
                phx-value-label_id={label.id}
                phx-target={@myself}
                class="flex items-center gap-x-1"
              >
                <div class="mr-1 h-2 w-2 rounded-full" style={"background-color:#{label.color}"}>
                </div>
                {label.name}
                <.icon name="hero-plus" class="size-3 text-gray-400 hover:text-gray-600" />
              </button>
            </div>
          </div>
        </div>

        <.button
          phx-click={JS.exec("data-cancel", to: "#add-label-to-filter")}
          phx-target={@myself}
          class="w-full"
        >
          Done
        </.button>
      </div>
    </.modal>
    """
  end

  defp label_modal(assigns) do
    ~H"""
    <.modal id="add-label">
      <span
        :if={@selected_query.labels != []}
        class="text-alpha-64 flex flex-col text-xs"
        data-testid="selected-labels-title"
      >
        LABELS
      </span>
      <div class={[
        "flex flex-wrap gap-x-1 pb-2",
        @selected_query.labels != [] && "border-alpha-8 border-b"
      ]}>
        <div
          :for={label <- @selected_query.labels}
          class="ring-alpha-8 my-2 flex w-fit items-center gap-x-1 truncate rounded-full px-2 py-1 text-xs text-gray-600 ring-1 ring-inset"
          data-testid="selected-labels"
        >
          <div class="mr-1 h-2 w-2 rounded-full" style={"background-color:#{label.color}"}></div>
          {label.name}

          <button
            :if={label in @selected_query.labels}
            phx-click="remove_object_label"
            phx-value-label_id={label.id}
            phx-target={@myself}
          >
            <.icon name="hero-x-mark" class="size-3 text-gray-400 hover:text-gray-600" />
          </button>
        </div>
      </div>
      <div class="mt-4 flex flex-col gap-y-4" data-testid="search-labels-form">
        <.form
          :let={f}
          for={%{"label_search" => @label_search}}
          class="border-alpha-8"
          phx-change="search_labels"
          phx-target={@myself}
        >
          <.input
            field={f[:label_search]}
            type="text"
            label="Search"
            phx-debounce
            phx-target={@myself}
          />
        </.form>

        <%!-- unselected labels --%>
        <% unselected_labels =
          Enum.filter(
            filter_labels(@labels, @label_search),
            &(&1 not in @selected_query.labels)
          ) %>
        <div :if={not Enum.empty?(unselected_labels)}>
          <span class="text-alpha-64 flex flex-col text-xs">
            ADD LABEL
          </span>
          <div class="flex flex-wrap gap-x-1">
            <div
              :for={label <- unselected_labels}
              class="ring-alpha-8 mt-1 flex w-fit items-center gap-x-1 truncate rounded-full px-2 py-1 text-xs text-gray-600 ring-1 ring-inset hover:bg-alpha-4"
              data-testid="unassigned-labels"
            >
              <button
                :if={label not in @selected_query.labels}
                phx-click="add_existing_label_to_selected_query"
                phx-value-label_id={label.id}
                phx-target={@myself}
                class="flex items-center gap-x-1"
              >
                <div class="mr-1 h-2 w-2 rounded-full" style={"background-color:#{label.color}"}>
                </div>
                {label.name}
                <.icon name="hero-plus" class="size-3 text-gray-400 hover:text-gray-600" />
              </button>
            </div>
          </div>
        </div>

        <%!-- create new label --%>
        <div :if={
          @label_search != "" and
            not Enum.any?(@labels, fn label ->
              String.downcase(label.name) == String.downcase(@label_search)
            end)
        }>
          <span class="text-alpha-64 flex flex-col text-sm">Create a new label</span>
          <div class="flex gap-x-1">
            <div class="ring-alpha-8 mt-1 mr-1 flex h-2 w-2 w-fit items-center gap-x-1 truncate rounded-full rounded-full px-2 py-3 text-xs text-gray-600 ring-1 ring-inset hover:bg-alpha-4">
              <button
                phx-click="add_new_label"
                phx-value-label_name={@label_search}
                phx-target={@myself}
                class="flex items-center gap-x-1"
              >
                <div class="mr-1 h-2 w-2 rounded-full" style="background-color:#FFFFFF"></div>
                <div class="text-gray-600">{@label_search}</div>
                <.icon name="hero-plus" class="size-3 text-gray-400 hover:text-gray-600" />
              </button>
            </div>
          </div>
        </div>

        <.button
          phx-click={JS.exec("data-cancel", to: "#add-label")}
          phx-target={@myself}
          class="w-full"
          data-testid="open-add-label-modal"
        >
          Done
        </.button>
      </div>
    </.modal>
    """
  end

  defp extract_variable_descriptions(query) do
    # Match comments in the format "-- var_name: description"
    regex = ~r/--\s*([a-zA-Z0-9_]+):\s*(.+)$/m

    regex
    |> Regex.scan(query)
    |> Map.new(fn [_full_match, var_name, description] ->
      {var_name, String.trim(description)}
    end)
  end

  defp filter_saved_queries(saved_queries, search, label_filter) do
    search = String.downcase(search || "")
    label_filter = Enum.map(label_filter, &String.downcase/1)

    Enum.filter(saved_queries, fn query ->
      labels = Enum.map(query.labels, fn label -> String.downcase(label.name) end)
      label_match? = Enum.any?(labels, fn label -> String.contains?(label, search) end)

      has_matching_label? = Enum.empty?(label_filter) || Enum.any?(labels, fn label -> label in label_filter end)

      matches_search? =
        String.contains?(String.downcase(query.title), search) or
          String.contains?(String.downcase(query.query), search) or
          label_match?

      has_matching_label? and matches_search?
    end)
  end

  defp filter_labels(labels, label_search) do
    label_search = String.downcase(label_search || "")

    Enum.filter(labels, fn label ->
      String.contains?(String.downcase(label.name), label_search)
    end)
  end

  defp update_saved_queries(socket, updated_query) do
    saved_queries =
      Enum.map(socket.assigns.saved_queries, fn saved_query ->
        if updated_query.id == saved_query.id do
          updated_query
        else
          saved_query
        end
      end)

    assigned_labels = derive_assigned_labels(saved_queries)

    assign(socket, saved_queries: saved_queries, selected_query: updated_query, assigned_labels: assigned_labels)
  end

  defp derive_assigned_labels(saved_queries) do
    saved_queries
    |> Enum.flat_map(fn query -> query.labels end)
    |> Enum.uniq()
  end
end
