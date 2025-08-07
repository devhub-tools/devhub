defmodule DevhubWeb.Components.CommandPalette do
  @moduledoc false
  use DevhubWeb, :live_component

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(
        results: [],
        search: ""
      )

    {:ok, socket}
  end

  attr :on_cancel, JS, default: %JS{}

  def render(assigns) do
    ~H"""
    <div
      id="command-palette"
      phx-hook="ListNavigation"
      class="relative z-50"
      role="dialog"
      aria-modal="true"
      data-toggle={
        toggle("#command-palette-backdrop")
        |> toggle("#command-palette-container")
        |> JS.focus(to: "#command-palette-search")
      }
      phx-window-keydown={
        hide("#command-palette-backdrop")
        |> hide("#command-palette-container")
      }
      phx-key="escape"
    >
      <div
        id="command-palette-backdrop"
        class="fixed inset-0 hidden backdrop-blur-sm transition-opacity"
        aria-hidden="true"
      >
      </div>

      <div
        id="command-palette-container"
        class="fixed inset-0 z-50 hidden w-screen overflow-y-auto p-4 sm:p-6 md:p-20"
      >
        <div
          class="ring-black/5 divide-alpha-8 bg-surface-2 mx-auto max-w-xl transform divide-y overflow-hidden rounded-xl shadow-2xl ring-1"
          phx-click-away={JS.exec("data-toggle", to: "##{@id}")}
        >
          <.form for={%{}} phx-change="search" phx-target={@myself}>
            <div class="grid grid-cols-1">
              <input
                id="command-palette-search"
                name="search"
                value={@search}
                type="text"
                class="bg-surface-2 col-start-1 row-start-1 h-12 w-full border-none pr-4 pl-11 text-base text-gray-900 outline-none placeholder:text-gray-400 focus:outline-none focus:ring-0 sm:text-sm"
                placeholder="Search..."
                role="combobox"
                aria-expanded="false"
                aria-controls="options"
                phx-debounce
              />
              <.icon
                name="hero-magnifying-glass"
                class="size-5 pointer-events-none col-start-1 row-start-1 ml-4 self-center text-gray-400"
              />
            </div>
          </.form>

          <div
            :if={not Enum.empty?(@results)}
            id="options"
            role="listbox"
            class="max-h-96 transform-gpu scroll-py-3 overflow-y-auto p-3"
          >
            <.link
              :for={result <- @results}
              id={"option-#{result.id}"}
              role="option"
              tabindex="-1"
              navigate={result.link}
              class="list-nav-item group flex cursor-pointer select-none items-center rounded-xl p-3 hover:bg-alpha-4 focus:bg-alpha-4 focus:outline-none"
            >
              <.icon name={result.icon} class="size-6" />
              <div class="flex h-10 w-full items-center justify-between">
                <div class="ml-4 flex-auto">
                  <span class="flex items-center gap-x-1 text-sm font-medium text-gray-700">
                    {result.title}
                    <div
                      :if={result.group}
                      class="flex w-fit items-center rounded bg-blue-200 px-2 py-1"
                    >
                      <span class="text-xs text-blue-900">{result.group}</span>
                    </div>
                  </span>
                  <p :if={result.subtitle} class="text-sm text-gray-500">{result.subtitle}</p>
                </div>
                <div class="text-alpha-64 text-xs">
                  {result.type}
                </div>
              </div>
            </.link>
          </div>

          <div
            :if={Enum.empty?(@results) and @search != ""}
            class="px-6 py-14 text-center text-sm sm:px-14"
          >
            <svg
              class="size-6 mx-auto text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              aria-hidden="true"
              data-slot="icon"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"
              />
            </svg>
            <p class="mt-4 font-semibold text-gray-900">No results found</p>
            <p class="mt-2 text-gray-500">
              We couldn’t find anything with that term. Please try again.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"search" => search}, socket) do
    opts =
      if socket.assigns.active_tab in [:table, :query] do
        id = socket.assigns.uri.path |> String.split("/") |> Enum.at(3)
        [database_id: id]
      else
        []
      end

    results = Devhub.search(socket.assigns.organization_user, search, opts)
    {:noreply, assign(socket, search: search, results: results)}
  end
end
