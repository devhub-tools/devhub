defmodule DevhubWeb.Components.QueryDesk.QueryHistory do
  @moduledoc false
  use DevhubWeb, :live_component

  alias Devhub.QueryDesk

  def mount(socket) do
    socket |> assign(search_form: %{"search" => ""}) |> ok()
  end

  def update(assigns, socket) do
    query_history = QueryDesk.get_query_history(assigns.database_id, user_id: assigns.user.id)

    socket
    |> assign(assigns)
    |> assign(query_history: query_history)
    |> push_event("set_query", %{"query" => ""})
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.link
        navigate={~p"/querydesk/databases/#{@database_id}/query"}
        class="ml-4 text-sm font-medium text-blue-600"
      >
        <.icon name="hero-arrow-left-solid" class="size-3" /> Tables
      </.link>
      <p class="text-alpha-64 border-alpha-8 mt-4 border-b px-4 pb-3 text-sm">Query history</p>
      <.form
        :let={f}
        for={@search_form}
        class="border-alpha-8 mt-4 border-b px-4 pb-4"
        phx-change="search_query_history"
        phx-target={@myself}
      >
        <.input field={f[:search]} type="text" placeholder="Search" phx-debounce />
      </.form>
      <ul class="divide-alpha-8 divide-y">
        <li
          :for={query <- @query_history}
          class="border-surface-3 group relative cursor-pointer p-4 px-4 text-xs hover:bg-alpha-4"
          phx-click="select_query"
          role="button"
          phx-value-id={query.id}
          phx-target={@myself}
        >
          <p class="truncate">{query.query}</p>
          <div class="mt-1 truncate text-gray-600">
            <format-date date={query.executed_at} format="relative" />
          </div>
        </li>
      </ul>
    </div>
    """
  end

  def handle_event("select_query", %{"id" => query_id}, socket) do
    query = Enum.find(socket.assigns.query_history, &(&1.id == query_id))

    socket
    |> push_event("set_query", %{"query" => query.query})
    |> noreply()
  end

  def handle_event("search_query_history", %{"search" => search}, socket) do
    query_history =
      QueryDesk.get_query_history(socket.assigns.database_id, user_id: socket.assigns.user.id, query: {:like, search})

    socket |> assign(query_history: query_history) |> noreply()
  end
end
