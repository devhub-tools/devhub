defmodule DevhubWeb.Live.QueryDesk.AuditLog do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.QueryDesk
  alias Devhub.Users

  def mount(params, _session, socket) do
    users = Users.list_organization_users(socket.assigns.organization.id)

    databases =
      socket.assigns.organization_user
      |> QueryDesk.list_databases()
      |> Enum.map(&Map.take(&1, [:id, :name, :group]))

    selected_database_id = params["database_id"]
    database = Enum.find(databases, fn database -> database.id == selected_database_id end)

    socket
    |> assign(
      page_title: "Devhub",
      databases: databases,
      filtered_databases: databases,
      users: users,
      filtered_users: users,
      selected_user: nil,
      selected_user_id: nil,
      selected_database: database,
      selected_database_id: selected_database_id,
      start_date: nil,
      end_date: nil,
      query_search: nil,
      queries: []
    )
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      start_date = start_date_from_params(params)
      end_date = end_date_from_params(socket.assigns.user.timezone, params)

      socket
      |> assign(
        start_date: start_date,
        end_date: end_date
      )
      |> fetch_queries()
      |> noreply()
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title="Audit log">
        <:actions>
          <.dropdown
            :if={not is_nil(assigns[:start_date]) and not is_nil(assigns[:end_date])}
            id="date-picker"
          >
            <:trigger>
              <div class="text-alpha-64 border-alpha-24 mb-1 flex items-center gap-x-1 border-b text-sm">
                <format-date date={@start_date} format="date" />
                <.icon name="hero-arrow-long-right-mini text-alpha-40" class="size-4" />
                <format-date date={@end_date} format="date" />
              </div>
            </:trigger>
            <div class="ring-alpha-8 bg-surface-4 mt-1 w-48 rounded p-4 text-sm ring-1">
              <.form for={%{}} phx-change="set_date_filter">
                <div class="flex flex-col gap-y-4">
                  <div>
                    <.input name="start_date" type="date" value={@start_date} label="Start date" />
                  </div>
                  <div>
                    <.input name="end_date" type="date" value={@end_date} label="End Date" />
                  </div>
                </div>
              </.form>
            </div>
          </.dropdown>
        </:actions>
      </.page_header>

      <div class="mb-4 grid grid-cols-3 items-center gap-x-2">
        <.form :let={f} for={%{}} phx-change="search_queries" phx-hook="PreventSubmit">
          <.input field={f[:query_search]} type="text" label="Search" phx-debounce />
        </.form>
        <div>
          <span class="text-alpha-64 block text-xs uppercase">User</span>
          <.dropdown_with_search
            filter_action="filter_users"
            filtered_objects={@filtered_users}
            friendly_action_name="User search"
            selected_object_name={@selected_user && @selected_user.name}
            select_action="select_user"
            data-testid="filter-users"
          >
            <:item :let={user}>
              <div class="flex flex-col gap-y-1">
                <div>{user.name}</div>
                <div class="text-alpha-64 text-xs">{user.email}</div>
              </div>
            </:item>
          </.dropdown_with_search>
        </div>
        <div>
          <span class="text-alpha-64 block text-xs uppercase">Database</span>
          <.dropdown_with_search
            filtered_objects={@filtered_databases}
            filter_action="filter_databases"
            friendly_action_name="Database search"
            selected_object_name={@selected_database && @selected_database.name}
            select_action="select_database"
          >
            <:item :let={database}>
              <div class="flex flex-col gap-y-1">
                <div>{database.name || "(New database)"}</div>
                <div class="text-alpha-64 text-xs">{database.group}</div>
              </div>
            </:item>
          </.dropdown_with_search>
        </div>
      </div>
      <div>
        <div class="overflow-hidden rounded-md">
          <ul class="grid gap-4">
            <li :for={query <- @queries} class="bg-surface-1 rounded-lg p-4 hover:bg-alpha-4">
              <.details class="w-full" id={query.id <> "-query-details"}>
                <.formatted_query
                  id={query.id <> "-query"}
                  query={query.query}
                  adapter={query.credential.database.adapter}
                />
                <:summary>
                  <.query_summary query={query}>
                    <div class="flex items-center justify-end">
                      <div class="flex flex-col items-end space-y-1">
                        <p :if={not query.failed} class="text-alpha-64 text-xs uppercase">
                          query ran at
                        </p>
                        <p :if={query.failed} class="text-alpha-64 text-xs uppercase">
                          query failed at
                        </p>
                        <format-date date={query.executed_at} class="text-sm"></format-date>
                      </div>
                      <div class="tooltip tooltip-left">
                        <.icon
                          :if={query.failed}
                          name="hero-exclamation-circle"
                          class="ml-2 h-5 w-5 text-red-500"
                        />
                        <pre class="tooltiptext text-wrap w-40">{query.error}</pre>
                      </div>
                    </div>
                  </.query_summary>
                  <div :if={query.analyze} class="mt-4 flex">
                    <.link_button href={~p"/querydesk/plan/#{query.id}"} target="_blank">
                      View plan
                    </.link_button>
                  </div>
                </:summary>
              </.details>
              <div class="mt-4">
                <button
                  phx-click={
                    toggle("##{query.id}-comments-details")
                    |> toggle("##{query.id}-show")
                    |> toggle("##{query.id}-hide")
                    |> JS.toggle_class("rotate-180", to: "##{query.id}-chevron")
                  }
                  class={[
                    "text-alpha-64 ml-auto flex cursor-pointer text-sm",
                    query.comments |> length() == 0 && "invisible"
                  ]}
                >
                  <span class="flex items-center gap-x-1">
                    <span id={query.id <> "-show"}>
                      Show
                    </span>
                    <span id={query.id <> "-hide"} class="hidden">
                      Hide
                    </span>
                    <span>comments ({query.comments |> length()})</span>
                    <span id={query.id <> "-chevron"}>
                      <.icon name="hero-chevron-down" class="h-4 w-4" />
                    </span>
                  </span>
                </button>

                <div id={query.id <> "-comments-details"} class="hidden">
                  <ul role="list">
                    <li
                      :for={comment <- query.comments}
                      class="border-alpha-8 mt-4 flex items-start justify-between rounded-md border p-4"
                    >
                      <div class="flex w-full flex-col gap-y-2">
                        <p class="font-bold text-blue-500">
                          <.user_block user={comment.created_by_user} />
                        </p>
                        <p class="text-alpha-72 font-bold">
                          {comment.comment}
                        </p>
                      </div>
                    </li>
                  </ul>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("filter_users", %{"name" => filter}, socket) do
    filter = String.downcase(filter)

    filtered_users =
      Enum.filter(socket.assigns.users, fn user ->
        String.contains?(String.downcase(user.name || ""), filter) or
          String.contains?(String.downcase(user.email || ""), filter)
      end)

    socket |> assign(:filtered_users, filtered_users) |> noreply()
  end

  def handle_event("clear_filter", _params, socket) do
    socket |> assign(filtered_users: socket.assigns.users, filtered_databases: socket.assigns.databases) |> noreply()
  end

  def handle_event("select_user", %{"id" => id}, socket) do
    user = Enum.find(socket.assigns.users, fn user -> user.id == id end)

    # If the user is already selected, deselect them
    if socket.assigns.selected_user_id == user.id do
      socket
      |> assign(selected_user: nil, selected_user_id: nil, filtered_users: socket.assigns.users)
      |> fetch_queries()
      |> noreply()
    else
      socket
      |> assign(selected_user: user, selected_user_id: user.id, filtered_users: socket.assigns.users)
      |> fetch_queries()
      |> noreply()
    end
  end

  def handle_event("filter_databases", %{"name" => filter}, socket) do
    filtered_databases =
      Enum.filter(socket.assigns.databases, fn database ->
        String.contains?(String.downcase(database.name || "(New database)"), String.downcase(filter))
      end)

    {:noreply, assign(socket, :filtered_databases, filtered_databases)}
  end

  def handle_event("select_database", %{"id" => id}, socket) do
    database = Enum.find(socket.assigns.databases, fn database -> database.id == id end)

    if socket.assigns.selected_database_id == database.id do
      socket
      |> assign(selected_database: nil, selected_database_id: nil, filtered_databases: socket.assigns.databases)
      |> fetch_queries()
      |> noreply()
    else
      socket
      |> assign(
        selected_database: database,
        selected_database_id: database.id,
        filtered_databases: socket.assigns.databases
      )
      |> fetch_queries()
      |> noreply()
    end
  end

  def handle_event("search_queries", %{"query_search" => search}, socket) do
    socket
    |> assign(query_search: search)
    |> fetch_queries()
    |> noreply()
  end

  defp fetch_queries(socket) do
    %{
      start_date: start_date,
      end_date: end_date,
      selected_user_id: selected_user_id,
      selected_database_id: selected_database_id,
      query_search: query_search,
      user: user
    } = socket.assigns

    filters =
      Enum.filter(
        [
          user_id: selected_user_id,
          query: {:like, query_search},
          start_date: start_date,
          end_date: end_date,
          database_id: selected_database_id,
          timezone: user.timezone
        ],
        fn {_k, v} -> not is_nil(v) end
      )

    queries = QueryDesk.query_audit_log(filters)

    assign(socket, :queries, queries)
  end
end
