defmodule DevhubWeb.Live.QueryDesk.Query do
  @moduledoc false
  use DevhubWeb, :live_view

  import Devhub.QueryDesk.Utils.QueryFromSelection

  alias Devhub.Integrations
  alias Devhub.Permissions
  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Databases.Adapter
  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.Users
  alias DevhubWeb.Components.QueryDesk.QueryLibrary

  require Logger

  def mount(%{"id" => database_id}, _session, socket) do
    {:ok, database} = QueryDesk.get_database(id: database_id, organization_id: socket.assigns.organization.id)

    ai_setup? =
      case Integrations.get_by(organization_id: socket.assigns.organization.id, provider: :ai) do
        {:ok, %{access_token: token}} when is_binary(token) -> true
        _not_setup -> false
      end

    if QueryDesk.can_access_database?(database, socket.assigns.organization_user) do
      schema =
        database
        |> Adapter.get_schema(socket.assigns.user.id)
        |> Enum.group_by(& &1.table, & &1.name)

      tables = schema |> Map.keys() |> Enum.sort()

      databases =
        socket.assigns.organization_user
        |> QueryDesk.list_databases()
        |> Enum.map(&Map.take(&1, [:id, :name, :group, :user_pins]))

      users = Users.list_organization_users(socket.assigns.organization.id)

      socket
      |> assign(
        page_title: "#{database.name} | Devhub",
        form_params: %{},
        database: Map.delete(database, :user),
        databases: databases,
        filtered_databases: databases,
        tables: tables,
        schema: Jason.encode!(schema),
        current_credential: database.default_credential || hd(database.credentials),
        query_changeset: nil,
        query: nil,
        saved_query_changeset: nil,
        show_shared_query_modal: false,
        query_running?: false,
        query_run_time: nil,
        queries: [],
        variables: %{},
        selected_query: nil,
        number_of_results: nil,
        users: users,
        ai_setup?: ai_setup?
      )
      |> ok()
    else
      {:ok, push_navigate(socket, to: ~p"/querydesk")}
    end
  rescue
    error ->
      Logger.error(error)

      {:ok,
       socket
       |> put_flash(:error, "Unable to connect to database.")
       |> push_navigate(to: ~p"/querydesk")}
  end

  # no database id provided
  def mount(_params, _session, socket) do
    case QueryDesk.list_databases(socket.assigns.organization_user) do
      [database | _rest] ->
        {:ok, push_navigate(socket, to: ~p"/querydesk/databases/#{database.id}/#{socket.assigns.live_action}")}

      [] ->
        {:ok, push_navigate(socket, to: ~p"/querydesk")}
    end
  end

  def handle_params(params, _uri, socket) do
    mode = Map.get(params, "mode", "query")
    query_id = Map.get(params, "query_id")
    conversation_id = Map.get(params, "conversation_id")
    preferences = socket.assigns.user.preferences["options"]["query"]

    query_options = %{
      "limit" => params["limit"] || preferences["limit"] || 500,
      "timeout" => params["timeout"] || preferences["timeout"] || 10
    }

    socket
    |> assign(
      query_options: query_options,
      mode: mode,
      selected_query_id: query_id,
      selected_conversation_id: conversation_id,
      search: params["search"],
      label_search: params["label_search"] || "",
      label_filter: String.split(params["label_filter"] || "", ",", trim: true)
    )
    |> then(fn socket ->
      if socket.assigns.mode == "query" do
        load_query(params, socket)
      else
        socket
      end
    end)
    |> noreply()
  end

  def render(assigns) do
    sidebar_offset =
      case assigns.mode do
        "library" -> "right-[21rem]"
        "ai" -> "right-[25rem]"
        _mode -> "right-0"
      end

    assigns = assign(assigns, sidebar_offset: sidebar_offset)

    ~H"""
    <div class={["absolute inset-0 left-20", @sidebar_offset]} id="run-query" phx-hook="SplitGrid">
      <div class="grid-column keep-style grid h-full">
        <div class="h-full overflow-auto py-4">
          <aside class="bg-surface-1 h-full overflow-y-auto rounded-r-lg" aria-label="Sidebar">
            <div :if={@database.group} class="bg-blue-300 p-2 text-center text-sm text-gray-900">
              {@database.group}
            </div>
            <div class="m-4">
              <div class="text-alpha-64 mt-4 block text-xs uppercase">
                Database
              </div>
              <.dropdown_with_search
                filtered_objects={
                  Enum.sort_by(
                    @filtered_databases,
                    &{Enum.empty?(&1.user_pins), String.downcase(&1.name || "")}
                  )
                }
                filter_action="filter_databases"
                friendly_action_name="Database search"
                selected_object_name={@database.name}
                select_action="select_database"
              >
                <:item :let={database}>
                  <div class="flex h-10 w-full items-center justify-between" data-testid={database.id}>
                    <div class="flex flex-col gap-y-1">
                      <div>{database.name || "(New database)"}</div>
                      <div class="text-alpha-64 text-xs">{database.group}</div>
                    </div>
                    <div>
                      <.icon
                        :if={not Enum.empty?(database.user_pins)}
                        class="size-4 bg-yellow-500"
                        name="hero-star-solid"
                      />
                    </div>
                  </div>
                </:item>
              </.dropdown_with_search>
            </div>
            <.database_table_list
              :if={@mode == "query"}
              id="table-list"
              tables={@tables}
              database={@database}
              user={@user}
              organization_user={@organization_user}
              selected={nil}
              proxy_password={assigns[:proxy_password]}
            />

            <.live_component
              :if={@mode == "library"}
              module={QueryLibrary}
              id="query-library"
              organization={@organization}
              organization_user={@organization_user}
              selected_query_id={@selected_query_id}
              database_id={@database.id}
              search={@search}
              label_search={@label_search}
              label_filter={@label_filter}
              uri={@uri}
              user={@user}
              variables={@variables}
            />

            <.live_component
              :if={@mode == "history"}
              module={DevhubWeb.Components.QueryDesk.QueryHistory}
              id="query-history"
              organization={@organization}
              user={@user}
              selected_query_id={@selected_query_id}
              database_id={@database.id}
            />

            <.live_component
              :if={@mode == "ai"}
              module={DevhubWeb.Components.QueryDesk.AiChat}
              id="ai-chat"
              organization={@organization}
              organization_user={@organization_user}
              selected_conversation_id={@selected_conversation_id}
              database_id={@database.id}
              database_adapter={@database.adapter}
              search={@search}
              uri={@uri}
              ai_setup?={@ai_setup?}
            />
          </aside>
        </div>
        <div class="gutter-col gutter-col-1 z-10 w-4"></div>
        <div class="overflow-auto">
          <div class="grid-row keep-style grid h-full">
            <div id="query-form-container">
              <.query_form
                id="query-form"
                mode={@mode}
                current_credential={@current_credential}
                database={@database}
                form_params={@form_params}
                schema={@schema}
                query_running?={@query_running?}
                query_run_time={@query_run_time}
                number_of_results={@number_of_results}
                query_options={@query_options}
              />
            </div>
            <div class="gutter-row gutter-row-1"></div>
            <div class="m-4 mt-1 overflow-auto rounded-lg">
              <div class="bg-surface-1 relative z-0 h-full flex-1">
                <div class="h-full overflow-auto">
                  <data-table id="query-result-table" phx-hook="DataTable" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <.modal
      :if={@saved_query_changeset && is_nil(@saved_query_changeset.data.id)}
      id="save-query-modal"
      show={true}
      on_cancel={JS.push("clear_saved_query_changeset")}
    >
      <div>
        <div class="mb-4 text-center">
          <h3 class="text-base font-semibold text-gray-900">
            Save query
          </h3>
        </div>
      </div>
      <.form
        :let={f}
        for={@saved_query_changeset}
        phx-submit="create_saved_query"
        phx-change="update_saved_query_form"
        class="focus-on-show flex flex-col gap-y-4"
      >
        <.input field={f[:title]} type="text" label="Name" />
        <.input field={f[:query]} type="textarea" label="Query" />
        <.input
          field={f[:private]}
          type="toggle"
          label="Private"
          tooltip="Private queries are only visible to you"
        />
        <div class="mt-6 sm:grid sm:grid-flow-row-dense sm:grid-cols-2 sm:gap-4">
          <.button
            type="button"
            variant="secondary"
            phx-click={JS.exec("data-cancel", to: "#save-query-modal")}
            aria-label={gettext("close")}
          >
            Cancel
          </.button>
          <.button type="submit" variant="primary">Save</.button>
        </div>
      </.form>
    </.modal>

    <.live_component
      :if={@show_shared_query_modal}
      id="shared-query-modal"
      module={DevhubWeb.Components.SharedQueryModal}
      organization={@organization}
      database={@database}
      organization_user={@organization_user}
      show_shared_query_modal={@show_shared_query_modal}
      results={assigns[:shared_query_results]}
      user={@user}
      query={@query}
      users={@users}
    />

    <.run_query_modal
      :if={not is_nil(@query_changeset)}
      number_of_queries={length(@queries)}
      query_changeset={@query_changeset}
      database={@database}
    />
    """
  end

  def handle_event("filter_databases", %{"name" => filter}, socket) do
    filtered_databases =
      Enum.filter(socket.assigns.databases, fn database ->
        String.contains?(String.downcase(database.name || "(New database)"), String.downcase(filter))
      end)

    {:noreply, assign(socket, :filtered_databases, filtered_databases)}
  end

  def handle_event("select_database", %{"id" => database_id}, socket) do
    params = update_uri_query(socket, %{"query_id" => socket.assigns.selected_query_id})

    socket
    |> push_navigate(to: ~p"/querydesk/databases/#{database_id}/#{socket.assigns.mode}?#{params}")
    |> noreply()
  end

  def handle_event("clear_filter", _params, socket) do
    socket |> assign(filtered_databases: socket.assigns.databases) |> noreply()
  end

  def handle_event("reset_local_storage", _params, socket) do
    socket
    |> push_event("reset_local_storage", %{})
    |> push_navigate(to: "#{socket.assigns.uri.path}?#{socket.assigns.uri.query}")
    |> noreply()
  end

  def handle_event("show_query_options", %{"query" => query_string, "selection" => selection}, socket) do
    queries =
      query_string
      |> query_from_selection(selection)
      |> QueryDesk.replace_query_variables(socket.assigns.variables)

    socket
    |> assign(
      queries: queries,
      query_changeset:
        Query.changeset(%{
          query: hd(queries),
          credential_id: socket.assigns.current_credential.id,
          limit: socket.assigns.query_options["limit"],
          timeout: socket.assigns.query_options["timeout"]
        })
    )
    |> noreply()
  end

  def handle_event("update_query_options", %{"query" => params}, socket) do
    socket
    |> assign(query_changeset: Query.changeset(params))
    |> noreply()
  end

  def handle_event("update_user_query_preferences", params, socket) do
    params = Map.take(params, ["limit", "timeout"])

    socket
    |> assign(query_options: params)
    |> save_preferences_and_patch("options", "query", params)
    |> noreply()
  end

  def handle_event("update_variables", params, socket) do
    socket
    |> assign(variables: params)
    |> noreply()
  end

  def handle_event("trigger_" <> _rest = event, _params, socket) do
    socket
    |> push_event(event, %{})
    |> noreply()
  end

  def handle_event("cancel_query", _params, socket) do
    socket.assigns.query && QueryDesk.cancel_query(socket.assigns.query, socket.assigns.query_task)

    socket
    |> maybe_finalize_results()
    |> push_event("query-result-table:custom_event", %{type: "streamDone", data: %{}})
    |> noreply()
  end

  def handle_event("run_query", %{"query" => query_string, "selection" => selection}, socket) do
    queries =
      query_string
      |> query_from_selection(selection)
      |> QueryDesk.replace_query_variables(socket.assigns.variables)

    %{
      organization_id: organization_id,
      current_credential: credential,
      user: %{id: user_id},
      query_options: %{"limit" => limit, "timeout" => timeout}
    } = socket.assigns

    socket
    |> run_query(%{
      organization_id: organization_id,
      credential_id: credential.id,
      queries: queries,
      is_system: false,
      user_id: user_id,
      limit: limit,
      timeout: timeout
    })
    |> noreply()
  end

  def handle_event("run_query_with_options", %{"query" => %{"analyze" => analyze} = params}, socket)
      when analyze in ["true", true] do
    %{
      organization_id: organization_id,
      user: %{id: user_id},
      query_options: %{"limit" => default_limit},
      queries: queries
    } = socket.assigns

    %{
      "credential_id" => credential_id,
      "timeout" => timeout
    } = params

    params = %{
      query: hd(queries),
      analyze: true,
      organization_id: organization_id,
      credential_id: credential_id,
      limit: params["limit"] || default_limit,
      is_system: false,
      user_id: user_id,
      run_on_approval: params["run_on_approval"] == "true",
      timeout: timeout
    }

    with {:ok, query} <- QueryDesk.create_query(params),
         {:ok, query} <- QueryDesk.analyze_query(query) do
      socket |> push_navigate(to: ~p"/querydesk/plan/#{query.id}") |> noreply()
    else
      _error ->
        socket |> put_flash(:error, "Failed to analyze query.") |> noreply()
    end
  end

  def handle_event("run_query_with_options", %{"query" => params}, socket) do
    %{
      organization_id: organization_id,
      user: %{id: user_id},
      query_options: %{"limit" => default_limit}
    } = socket.assigns

    %{
      "credential_id" => credential_id,
      "timeout" => timeout
    } = params

    socket
    |> run_query(%{
      queries: socket.assigns.queries,
      organization_id: organization_id,
      credential_id: credential_id,
      limit: params["limit"] || default_limit,
      is_system: false,
      user_id: user_id,
      run_on_approval: params["run_on_approval"] == "true",
      timeout: timeout
    })
    |> assign(query_changeset: nil)
    |> noreply()
  end

  def handle_event("query_finished", %{"numberOfRows" => rows}, socket) do
    socket
    |> assign(number_of_results: rows)
    |> noreply()
  end

  def handle_event("clear_query", _params, socket) do
    socket |> assign(query_changeset: nil) |> noreply()
  end

  def handle_event("clear_saved_query_changeset", _params, socket) do
    socket |> assign(saved_query_changeset: nil) |> noreply()
  end

  # updating saved query
  def handle_event("save_query", params, %{assigns: %{selected_query_id: id}} = socket) when is_binary(id) do
    params = Map.take(params, ["title", "query", "private"])

    with {:ok, query} <- QueryDesk.get_saved_query(id: id, organization_id: socket.assigns.organization.id),
         {:ok, _query} <- QueryDesk.update_saved_query(query, params) do
      send_update(QueryLibrary,
        id: "query-library",
        organization: socket.assigns.organization,
        organization_user: socket.assigns.organization_user,
        selected_query_id: socket.assigns.selected_query_id,
        database_id: socket.assigns.database.id,
        search: socket.assigns.search,
        uri: socket.assigns.uri,
        label_search: socket.assigns.label_search,
        label_filter: socket.assigns.label_filter,
        variables: socket.assigns.variables
      )

      socket |> put_flash(:info, "Query updated successfully.") |> noreply()
    else
      _error ->
        socket |> put_flash(:info, "Failed to update query.") |> noreply()
    end
  end

  # show form for new saved query
  def handle_event("save_query", %{"query" => query_string, "selection" => selection}, socket) do
    query_string = query_from_selection(query_string, selection)

    changeset = SavedQuery.changeset(%{query: query_string})

    socket |> assign(saved_query_changeset: changeset) |> noreply()
  end

  def handle_event("update_saved_query_form", %{"saved_query" => params}, socket) do
    changeset = SavedQuery.changeset(params)

    socket
    |> assign(saved_query_changeset: changeset)
    |> noreply()
  end

  def handle_event(
        "create_saved_query",
        %{"saved_query" => %{"query" => query, "title" => title, "private" => private}},
        socket
      ) do
    case QueryDesk.save_query(%{
           organization_id: socket.assigns.organization.id,
           private: private,
           created_by_user_id: socket.assigns.user.id,
           title: title,
           query: query
         }) do
      {:ok, _query} ->
        socket
        |> assign(saved_query_changeset: nil)
        |> put_flash(:info, "Query saved successfully.")
        |> noreply()

      {:error, changeset} ->
        socket |> assign(saved_query_changeset: changeset) |> noreply()
    end
  end

  def handle_event("show_shared_query_modal", params, socket) do
    results = params["data"]["results"]

    query = params["query"]

    if query == "" do
      noreply(socket)
    else
      socket
      |> assign(show_shared_query_modal: true, shared_query_results: results, query: query)
      |> noreply()
    end
  end

  # ignore sort events on this view
  def handle_event("sort", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("export", _params, socket) do
    socket |> push_event("query-result-table:custom_event", %{type: "export", data: %{}}) |> noreply()
  end

  def handle_info(:close_shared_query_modal, socket) do
    socket |> assign(show_shared_query_modal: false) |> noreply()
  end

  def handle_info({:query_stream, msg}, %{assigns: %{multiple: true, query: current_query}} = socket) do
    case msg do
      {:chunk, {:ok, _chunk}, {:error, error_msg}} ->
        QueryDesk.update_query(current_query, %{error: error_msg, failed: true})

        socket
        |> assign(results: Map.put(socket.assigns.results, current_query.id, %{error: error_msg}))
        |> noreply()

      {:chunk, {:ok, chunk}} ->
        {:ok, result} = :brotli.decode(chunk)
        %{"command" => command, "num_rows" => num_rows} = Jason.decode!(result)
        existing_rows = socket.assigns.results[current_query.id][:num_rows] || 0

        socket
        |> assign(
          results:
            Map.put(socket.assigns.results, current_query.id, %{command: command, num_rows: existing_rows + num_rows})
        )
        |> noreply()

      :done ->
        Phoenix.PubSub.unsubscribe(Devhub.PubSub, socket.assigns.query.id)

        socket
        |> run_next_query(socket.assigns.queries)
        |> noreply()
    end
  end

  def handle_info({:query_stream, msg}, %{assigns: %{query: %Query{} = query}} = socket) do
    case msg do
      {:chunk, {:ok, chunk}, {:error, error_msg}} ->
        QueryDesk.update_query(query, %{error: error_msg, failed: true})

        socket
        |> push_event("query-result-table:custom_event", %{type: "streamResult", data: %{chunk: Base.encode64(chunk)}})
        |> noreply()

      {:chunk, {:ok, chunk}} ->
        socket
        |> push_event("query-result-table:custom_event", %{type: "streamResult", data: %{chunk: Base.encode64(chunk)}})
        |> noreply()

      :done ->
        Phoenix.PubSub.unsubscribe(Devhub.PubSub, query.id)

        socket
        |> maybe_finalize_results()
        |> push_event("query-result-table:custom_event", %{type: "streamDone", data: %{}})
        |> noreply()
    end
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp run_query(socket, %{queries: [query]} = params) do
    with {:ok, query} <- params |> Map.put(:query, query) |> QueryDesk.create_query(),
         :ok <- Phoenix.PubSub.subscribe(Devhub.PubSub, query.id),
         {:ok, {:stream, stream_task}, query} <- QueryDesk.run_query(query, stream?: true) do
      socket
      |> assign(
        query: query,
        query_task: stream_task,
        multiple: false,
        query_running?: true,
        query_start_time: System.monotonic_time(:millisecond),
        query_run_time: nil
      )
      |> clear_flash()
      |> push_event("query-result-table:custom_event", %{type: "startStream", data: %{}})
    else
      {:error, :pending_approval, _query} ->
        put_flash(socket, :info, "Query is pending approval.")

      {:error, %Ecto.Changeset{}} ->
        put_flash(socket, :error, "No query to run.")

      {:error, error} ->
        put_flash(socket, :error, error)
    end
  end

  defp run_query(socket, %{queries: queries} = params) do
    credential =
      Enum.find(socket.assigns.database.credentials, fn
        credential -> credential.id == params.credential_id
      end)

    if credential.reviews_required == 0 do
      queries =
        Enum.map(queries, fn query ->
          {:ok, query} = params |> Map.put(:query, query) |> QueryDesk.create_query()
          query
        end)

      socket
      |> assign(
        queries: queries,
        multiple: true,
        results: %{},
        query_running?: true,
        query_start_time: System.monotonic_time(:millisecond),
        query_run_time: nil
      )
      |> clear_flash()
      |> push_event("query-result-table:custom_event", %{type: "startStream", data: %{}})
      |> run_next_query(queries)
    else
      # if reviews are required we combine to a single query for approval and will run separately after approval
      {:ok, _query} =
        params
        |> Map.put(:query, Enum.join(queries, ";\n"))
        |> QueryDesk.create_query()

      put_flash(socket, :info, "Query is pending approval.")
    end
  end

  defp run_next_query(socket, []) do
    maybe_finalize_results(socket)
  end

  defp run_next_query(socket, [query | queries]) do
    with :ok <- Phoenix.PubSub.subscribe(Devhub.PubSub, query.id),
         {:ok, {:stream, stream_task}, query} <- QueryDesk.run_query(query, stream?: true) do
      assign(socket, queries: queries, query: query, query_task: stream_task, query_run_time: nil)
    else
      _error ->
        put_flash(socket, :error, "Failed to run queries.")
    end
  end

  defp maybe_finalize_results(%{assigns: %{results: results}} = socket) when map_size(results) > 0 do
    results =
      results
      |> Enum.sort_by(fn {query_id, _result} -> query_id end)
      |> Enum.map(fn
        {_query_id, %{error: error}} -> "ERROR: #{error}"
        {_query_id, %{command: command, num_rows: num_rows}} -> "#{command} #{num_rows}"
      end)

    socket
    |> assign(
      query: nil,
      query_task: nil,
      query_running?: false,
      number_of_results: length(results),
      query_run_time: System.monotonic_time(:millisecond) - socket.assigns.query_start_time,
      results: %{}
    )
    |> push_event("query-result-table:custom_event", %{type: "queryResult", data: %{results: results}})
  end

  defp maybe_finalize_results(socket) do
    assign(socket,
      query: nil,
      query_task: nil,
      query_running?: false,
      query_run_time: System.monotonic_time(:millisecond) - socket.assigns.query_start_time,
      results: %{}
    )
  end

  defp load_query(params, socket) do
    with shared_query_id when is_binary(shared_query_id) <- Map.get(params, "shared_query_id"),
         {:ok, shared_query} <- QueryDesk.get_shared_query(id: shared_query_id) || {:error, :shared_query_expired},
         true <-
           (not shared_query.restricted_access or
              (socket.assigns.user.id == shared_query.created_by_user_id or
                 Permissions.can?(:read, shared_query, socket.assigns.organization_user))) || {:error, :unauthorized} do
      socket = push_event(socket, "set_query", %{"query" => shared_query.query})

      if shared_query.results do
        push_event(socket, "query-result-table:custom_event", %{
          type: "streamResult",
          data: %{chunk: Base.encode64(shared_query.results)}
        })
      else
        socket
      end
    else
      {:error, :unauthorized} ->
        socket
        |> put_flash(:error, "You are not authorized to access this shared query.")
        |> push_navigate(to: ~p"/querydesk/shared-queries")

      {:error, :shared_query_expired} ->
        socket
        |> put_flash(:error, "This shared query has expired.")
        |> push_navigate(to: ~p"/querydesk/shared-queries")

      _load_from_local_storage ->
        push_event(socket, "load_from_local_storage", %{"localStorageKey" => socket.assigns.database.id})
    end
  end
end
