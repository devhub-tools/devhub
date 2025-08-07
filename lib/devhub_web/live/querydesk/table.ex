defmodule DevhubWeb.Live.QueryDesk.Table do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations
  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Databases.Adapter
  alias DevhubWeb.Components.QueryDesk.ColumnFilter

  def mount(%{"id" => database_id, "table" => table}, _session, socket) do
    {:ok, database} = QueryDesk.get_database(id: database_id, organization_id: socket.assigns.organization.id)

    if QueryDesk.can_access_database?(database, socket.assigns.organization_user) do
      schema =
        database
        |> Adapter.get_schema(socket.assigns.user.id)
        |> Enum.group_by(& &1.table, & &1)

      tables = schema |> Map.keys() |> Enum.sort()

      columns = Map.new(schema[table], &{&1.name, Map.take(&1, [:fkey_table_name, :is_primary_key])})

      primary_key_name =
        case Enum.find(columns, fn {_name, %{is_primary_key: is_primary_key}} -> is_primary_key end) do
          {primary_key_name, _info} -> primary_key_name
          _nil -> nil
        end

      databases =
        socket.assigns.organization_user
        |> QueryDesk.list_databases()
        |> Enum.map(&Map.take(&1, [:id, :name, :group, :user_pins]))

      ai_setup? =
        case Integrations.get_by(organization_id: socket.assigns.organization.id, provider: :ai) do
          {:ok, %{access_token: token}} when is_binary(token) -> true
          _not_setup -> false
        end

      socket =
        assign(socket,
          page_title: "#{table} | #{database.name} | Devhub",
          database: database,
          databases: databases,
          filtered_databases: databases,
          tables: tables,
          table: table,
          columns: columns,
          changes: %{},
          update_queries: [],
          primary_key_name: primary_key_name,
          current_credential: database.default_credential,
          column_filters: ColumnFilter.Form.changeset(%{filters: []}),
          ai_setup?: ai_setup?
        )

      {:ok, socket}
    else
      {:ok, push_navigate(socket, to: ~p"/querydesk")}
    end
  rescue
    _error ->
      {:ok,
       socket
       |> put_flash(:error, "Unable to connect to database.")
       |> push_navigate(to: ~p"/querydesk")}
  end

  def handle_params(params, _uri, socket) do
    socket =
      if connected?(socket) do
        socket
        |> assign(:order_by, parse_order_by(params["order_by"]))
        |> assign(:column_filters, parse_column_filters(params["filters"] || ""))
        |> fetch_table_data()
      else
        socket
      end

    {:noreply, socket}
  end

  def render(assigns) do
    assigns = assign(assigns, number_of_changes: map_size(assigns.changes))

    ~H"""
    <div class="absolute inset-0 left-20" id="table-view" phx-hook="SplitGrid">
      <div class="grid-column keep-style grid h-full">
        <div class="overflow-auto py-4">
          <aside class="bg-surface-1 h-full overflow-y-auto rounded-r-lg" aria-label="Sidebar">
            <div class="m-4">
              <div class="text-alpha-64 block text-xs uppercase">
                Database
              </div>
              <.dropdown_with_search
                filtered_objects={
                  Enum.sort_by(
                    @filtered_databases,
                    &{Enum.empty?(&1.user_pins), String.downcase(&1.name || "(New database)")}
                  )
                }
                filter_action="filter_databases"
                friendly_action_name="Database search"
                selected_object_name={@database.name}
                select_action="select_database"
              >
                <:item :let={database}>
                  <div
                    class="flex h-10 w-full items-center justify-between "
                    data-testid={database.id}
                  >
                    <div class="flex flex-col gap-y-1">
                      <div>{database.name}</div>
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
              id="table-list"
              tables={@tables}
              selected={@table}
              database={@database}
              user={@user}
              organization_user={@organization_user}
              ai_setup?={@ai_setup?}
              proxy_password={assigns[:proxy_password]}
            />
          </aside>
        </div>
        <div class="gutter-col gutter-col-1 z-10 w-4"></div>
        <div class="relative m-4 overflow-auto rounded-lg">
          <.column_filter columns={@columns} column_filters={@column_filters} />
          <div class="bg-surface-1 relative z-0 h-full flex-1">
            <div class="h-full overflow-auto">
              <data-table
                id="query-result-table"
                phx-hook="DataTable"
                editable={true}
                filterable={true}
                sortable={true}
                primaryKeyName={assigns[:primary_key_name]}
                orderBy={Jason.encode!(assigns[:order_by])}
                changes={Jason.encode!(assigns[:changes])}
              />
            </div>
          </div>

          <div :if={@number_of_changes > 0} class="absolute right-0 bottom-0 left-0 bg-blue-100 p-3">
            <div class="flex justify-between">
              <div>
                <button
                  phx-click="discard_changes"
                  class="rounded bg-gray-200 px-2 py-1 text-xs font-semibold hover:bg-gray-300"
                >
                  Discard changes
                </button>
                <span class="ml-1 text-xs">
                  {pluralize_unit(@number_of_changes, "changed row")}
                </span>
              </div>
              <div class="flex items-center gap-x-2">
                <.credential_dropdown
                  credentials={@database.credentials}
                  current_credential={@current_credential}
                />
                <div class="relative">
                  <button
                    phx-click={JS.toggle(to: "#preview-changes")}
                    phx-click-away={JS.hide(to: "#preview-changes")}
                    class="rounded bg-gray-200 px-2 py-1 text-xs font-semibold hover:bg-gray-300"
                  >
                    Preview changes
                  </button>
                  <div
                    id="preview-changes"
                    class="bg-surface-4 absolute -right-14 bottom-11 hidden w-fit divide-y divide-gray-700 rounded-md px-4 ring-1 ring-gray-600 focus:outline-none"
                  >
                    <div :for={query <- @update_queries} class="py-3">
                      <pre
                        id={query}
                        phx-hook="SqlHighlight"
                        data-query={query}
                        data-adapter={@database.adapter}
                      />
                    </div>
                  </div>
                </div>
                <button
                  phx-click="apply_changes"
                  class="rounded bg-gray-200 px-2 py-1 text-xs font-semibold hover:bg-gray-300"
                >
                  Save
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("add_column_filter", %{"field" => field}, socket) do
    form = socket.assigns.column_filters
    filters = (form.changes[:filters] || []) |> Enum.map(& &1.changes) |> Enum.reverse()
    updated_filters = Enum.reverse([%{column: field, value: "", operator: :contains} | filters])
    changeset = ColumnFilter.Form.changeset(%{filters: updated_filters})

    socket
    |> assign(:column_filters, changeset)
    |> noreply()
  end

  def handle_event("remove_column_filter", %{"index" => index}, socket) do
    filters =
      socket.assigns.column_filters
      |> Ecto.Changeset.get_field(:filters)
      |> List.delete_at(String.to_integer(index))
      |> Enum.map_join(",", &"#{&1.column}:#{&1.operator}:#{&1.value}")

    socket
    |> patch_current(%{"filters" => filters})
    |> noreply()
  end

  def handle_event("apply_filters", %{"form" => params}, socket) do
    filters =
      params
      |> ColumnFilter.Form.changeset()
      |> Ecto.Changeset.get_field(:filters)
      |> Enum.map_join(",", &"#{&1.column}:#{&1.operator}:#{&1.value}")

    socket
    |> patch_current(%{"filters" => filters})
    |> noreply()
  end

  def handle_event("sort", %{"field" => field}, socket) do
    socket
    |> patch_current(%{"order_by" => next_query_param(field, socket.assigns[:order_by])})
    |> noreply()
  end

  def handle_event("select_database", %{"id" => database_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/querydesk/databases/#{database_id}/query")}
  end

  def handle_event("clear_filter", _params, socket) do
    socket |> assign(filtered_databases: socket.assigns.databases) |> noreply()
  end

  def handle_event("filter_databases", %{"name" => filter}, socket) do
    filtered_databases =
      Enum.filter(socket.assigns.databases, fn database ->
        String.contains?(String.downcase(database.name), String.downcase(filter))
      end)

    {:noreply, assign(socket, :filtered_databases, filtered_databases)}
  end

  def handle_event(
        "select_credential",
        %{"id" => credential_id},
        %{assigns: %{database: %{credentials: credentials}}} = socket
      ) do
    credential = Enum.find(credentials, fn credential -> credential.id == credential_id end)
    {:noreply, assign(socket, :current_credential, credential)}
  end

  def handle_event("discard_changes", _params, socket) do
    {:noreply, assign(socket, changes: %{})}
  end

  def handle_event("discard_pending_change", _params, socket) do
    {:noreply, assign(socket, pending_change: nil, selected_field: nil)}
  end

  def handle_event("stage_changes", %{"primary_key_value" => primary_key_value} = params, socket) do
    params = Map.delete(params, "primary_key_value")

    row_changes =
      socket.assigns.changes
      |> Map.get(primary_key_value, %{})
      |> Map.merge(params)

    changes = Map.put(socket.assigns.changes, primary_key_value, row_changes)

    update_queries = build_queries_for_changes(socket.assigns.table, socket.assigns.primary_key_name, changes)

    socket |> assign(changes: changes, update_queries: update_queries) |> noreply()
  end

  def handle_event("unstage_changes", %{"primary_key_value" => primary_key_value} = params, socket) do
    keys = params |> Map.delete("primary_key_value") |> Map.keys()

    row_changes =
      socket.assigns.changes
      |> Map.get(primary_key_value, %{})
      |> Map.drop(keys)

    changes =
      if row_changes == %{} do
        Map.delete(socket.assigns.changes, primary_key_value)
      else
        Map.put(socket.assigns.changes, primary_key_value, row_changes)
      end

    update_queries = build_queries_for_changes(socket.assigns.table, socket.assigns.primary_key_name, changes)

    socket |> assign(changes: changes, update_queries: update_queries) |> noreply()
  end

  def handle_event("apply_changes", _params, socket) do
    results =
      Enum.map(socket.assigns.update_queries, fn query_string ->
        {:ok, query} =
          QueryDesk.create_query(%{
            organization_id: socket.assigns.organization.id,
            credential_id: socket.assigns.current_credential.id,
            query: query_string,
            is_system: false,
            user_id: socket.assigns.user.id
          })

        case QueryDesk.run_query(query) do
          {:ok, _result, _query} ->
            :ok

          {:error, :pending_approval, _query} ->
            :pending_approval

          _error ->
            :error
        end
      end)

    socket =
      cond do
        Enum.any?(results, fn result -> result == :error end) ->
          put_flash(socket, :error, "Error applying changes.")

        Enum.any?(results, fn result -> result == :pending_approval end) ->
          put_flash(socket, :info, "Changes are pending approval.")

        true ->
          put_flash(socket, :info, "Changes applied successfully.")
      end

    socket |> assign(:changes, %{}) |> fetch_table_data() |> noreply()
  end

  def handle_event("query_finished", _params, socket) do
    noreply(socket)
  end

  def handle_info({:query_stream, msg}, socket) do
    case msg do
      {:chunk, {:ok, chunk}, {:error, _error_msg}} ->
        socket
        |> push_event("query-result-table:custom_event", %{type: "streamResult", data: %{chunk: Base.encode64(chunk)}})
        |> noreply()

      {:chunk, {:ok, chunk}} ->
        socket
        |> push_event("query-result-table:custom_event", %{type: "streamResult", data: %{chunk: Base.encode64(chunk)}})
        |> noreply()

      :done ->
        socket.assigns.query && Phoenix.PubSub.unsubscribe(Devhub.PubSub, socket.assigns.query.id)

        socket
        |> assign(query: nil)
        |> push_event("query-result-table:custom_event", %{type: "streamDone", data: %{}})
        |> noreply()
    end
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp fetch_table_data(%{assigns: assigns} = socket) do
    filters =
      (assigns.column_filters.changes[:filters] || [])
      |> Enum.filter(& &1.valid?)
      |> Enum.map(&Ecto.Changeset.apply_changes/1)

    with {:ok, query} <-
           Adapter.get_table_data(assigns.database, assigns.user.id, assigns.table,
             order_by: assigns[:order_by],
             filters: filters
           ),
         :ok <- Phoenix.PubSub.subscribe(Devhub.PubSub, query.id),
         {:ok, {:stream, _stream_task}, query} <- QueryDesk.run_query(query, stream?: true) do
      socket
      |> assign(query: query)
      |> push_event("query-result-table:custom_event", %{type: "startStream", data: %{}})
    else
      {:error, error} ->
        socket
        |> put_flash(:error, error)
        |> push_event("query-result-table:custom_event", %{type: "queryResult", data: %{columns: [], rows: []}})
    end
  end

  defp build_queries_for_changes(table, primary_key_name, changes) do
    Enum.map(changes, fn {primary_key_value, row_changes} ->
      for_result = for({column_name, value} <- row_changes, do: "\"#{column_name}\" = '#{value}'")

      set =
        Enum.join(for_result, ",\n    ")

      ~s(UPDATE "#{table}" \nSET #{set} \nWHERE "#{primary_key_name}" = '#{primary_key_value}';)
    end)
  end

  defp next_query_param(field, %{direction: :asc, field: current_field}) when field == current_field, do: "-#{field}"
  defp next_query_param(field, _current_field), do: field

  defp parse_order_by("-" <> field), do: %{direction: :desc, field: field}
  defp parse_order_by(field) when is_binary(field), do: %{direction: :asc, field: field}
  defp parse_order_by(_field), do: nil

  defp parse_column_filters(filters) do
    filters =
      filters
      |> String.split(",", trim: true)
      |> Enum.flat_map(fn filter ->
        case String.split(filter, ":", parts: 3) do
          [column, operator, value] -> [%{column: column, operator: operator, value: value}]
          _other -> []
        end
      end)

    ColumnFilter.Form.changeset(%{filters: filters})
  end
end
