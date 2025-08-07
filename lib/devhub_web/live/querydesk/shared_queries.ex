defmodule DevhubWeb.Live.QueryDesk.SharedQueries do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.QueryDesk

  def mount(_params, _session, socket) do
    shared_queries = QueryDesk.list_shared_queries(socket.assigns.organization_user)

    {:ok, assign(socket, shared_queries: shared_queries)}
  end

  def handle_params(params, _uri, socket) do
    filter = params["filter"] || "shared_with_me"

    socket |> assign(filter: filter) |> noreply()
  end

  def render(assigns) do
    shared_queries = filter_shared_queries(assigns.shared_queries, assigns.filter, assigns.organization_user)

    assigns = assign(assigns, filtered_shared_queries: shared_queries)

    ~H"""
    <div>
      <.page_header title="Shared queries">
        <:actions>
          <div class="bg-alpha-4 divide-alpha-16 border-alpha-16 flex divide-x rounded border text-sm">
            <.link
              patch={~p"/querydesk/shared-queries?filter=shared_with_me"}
              class={"#{@filter == "shared_with_me" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
            >
              Shared with me
            </.link>
            <.link
              patch={~p"/querydesk/shared-queries?filter=shared_by_me"}
              class={"#{@filter == "shared_by_me" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
            >
              Shared by me
            </.link>
            <.link
              patch={~p"/querydesk/shared-queries?filter=all"}
              class={"#{@filter == "all" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
            >
              All shared queries
            </.link>
          </div>
        </:actions>
      </.page_header>

      <div
        :if={Enum.empty?(@filtered_shared_queries)}
        class="border-alpha-16 rounded-lg border-2 border-dashed p-12 text-center hover:border-alpha-24"
      >
        <.icon name="hero-share" class="size-10 mx-auto text-gray-500" />
        <h3 class="mt-2 text-sm font-semibold text-gray-900">
          No shared queries available
        </h3>
      </div>

      <div class="flex flex-col gap-y-4">
        <li
          :for={query <- @filtered_shared_queries}
          class="pending-query bg-surface-1 relative rounded-lg p-4 hover:bg-alpha-4"
        >
          <div class="flex flex-col gap-y-1">
            <div class="flex justify-between">
              <div class="mb-2 truncate text-left">{query.query}</div>
              <div class="flex items-center gap-x-2">
                <copy-button
                  icon="link"
                  value={"#{DevhubWeb.Endpoint.url()}/querydesk/databases/#{query.database.id}/query?shared_query_id=#{query.id}"}
                />
                <.link_button navigate={
                  ~p"/querydesk/databases/#{query.database.id}/query?shared_query_id=#{query.id}"
                }>
                  View
                </.link_button>

                <.button
                  :if={
                    query.created_by_user_id == @organization_user.user_id or
                      @organization_user.permissions.super_admin
                  }
                  phx-click="delete_shared_query"
                  phx-value-id={query.id}
                  data-confirm="Are you sure you want to delete this shared query?"
                  variant="destructive"
                >
                  Delete
                </.button>
              </div>
            </div>
            <div>
              <p class="truncate text-left text-xs text-gray-600">
                <span class="text-alpha-64">database:</span> {query.database.name}
              </p>
              <p class="truncate text-left text-xs text-gray-600">
                <span class="text-alpha-64">shared by:</span> {query.created_by_user.name}
              </p>
              <p class="truncate text-left text-xs text-gray-600">
                <span class="text-alpha-64">expires at:</span>
                <span :if={not is_nil(query.expires_at)}>
                  <format-date date={query.expires_at} />
                </span>
                <span :if={is_nil(query.expires_at)}>Never</span>
              </p>

              <p class="truncate text-left text-xs text-gray-600">
                <span class="text-alpha-64">results included:</span> {query.include_results}
              </p>
              <p
                :if={not Enum.empty?(query.permissions) and @filter == "shared_by_me"}
                class="truncate text-left text-xs text-gray-600"
              >
                <div class="flex items-center gap-x-2">
                  <span class="text-alpha-64 text-xs">shared with:</span>
                  <ul class="flex items-center gap-x-2">
                    <li :for={permission <- query.permissions}>
                      <div :if={not is_nil(permission.role_id)} class="flex text-xs">
                        <div class="flex items-center gap-x-3">
                          <div class="text-xs text-gray-600">
                            - {permission.role.name} (role)
                          </div>
                        </div>
                      </div>
                      <div :if={not is_nil(permission.organization_user_id)}>
                        <div class="text-xs text-gray-600">
                          - {permission.organization_user.user.name}
                        </div>
                      </div>
                    </li>
                  </ul>
                </div>
              </p>
            </div>
          </div>
          <div class="bg-surface-3 mt-4 max-h-48 overflow-auto break-all rounded p-4">
            <pre
              id={Ecto.UUID.generate()}
              phx-hook="SqlHighlight"
              data-query={query.query}
              data-adapter={query.database.adapter}
            />
          </div>
        </li>
      </div>
    </div>
    """
  end

  def handle_event("delete_shared_query", %{"id" => id}, socket) do
    shared_queries = socket.assigns.shared_queries
    shared_query = Enum.find(shared_queries, fn query -> query.id == id end)

    case QueryDesk.delete_shared_query(shared_query) do
      {:ok, _shared_query} ->
        shared_queries = Enum.filter(shared_queries, fn query -> query.id != id end)
        {:noreply, assign(socket, shared_queries: shared_queries)}

      _error ->
        socket |> put_flash(:error, "Failed to delete shared query") |> noreply()
    end
  end

  defp filter_shared_queries(shared_queries, filter, organization_user) do
    Enum.filter(shared_queries, fn query ->
      (filter == "shared_by_me" and query.created_by_user_id == organization_user.user_id) or
        (filter == "shared_with_me" and query.created_by_user_id != organization_user.user_id) or
        filter == "all"
    end)
  end
end
