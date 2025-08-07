defmodule DevhubWeb.Components.Filter do
  @moduledoc false
  use DevhubWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(filtered_teams: assigns.teams)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center">
      <!-- start team filter -->
      <div class="w-60">
        <div
          phx-click={toggle("#team-options")}
          phx-click-away={hide("#team-options")}
          class="relative"
        >
          <form action="javascript:void(0);" class="-mt-2">
            <.input
              name="filter_teams"
              type="text"
              value={@selected_team_name}
              phx-change="filter_teams"
              phx-target={@myself}
              role="combobox"
              aria-controls="options"
              aria-expanded="false"
            />
            <button
              type="button"
              class="absolute inset-y-0 top-0 right-0 flex items-center rounded-r-md px-2 focus:outline-none"
            >
              <.icon name="hero-chevron-up-down" class="h-5 w-5 text-gray-400" />
            </button>
          </form>
        </div>

        <ul
          class="bg-surface-2 absolute z-10 mt-1 hidden max-h-56 w-60 overflow-auto rounded-md py-1 ring-1 ring-gray-100 ring-opacity-5 focus:outline-none sm:text-sm"
          id="team-options"
          role="listbox"
        >
          <li
            :for={team <- @filtered_teams}
            phx-click="select_team"
            phx-target={@myself}
            phx-value-team_id={team.id}
            class="relative cursor-default select-none py-2 pr-9 pl-3 text-gray-900 hover:bg-blue-100"
            role="option"
          >
            <div class="flex items-center">
              {team.name}
            </div>
            <span
              :if={team.id == @selected_team_id}
              class="absolute inset-y-0 right-0 flex items-center pr-4 text-blue-600"
            >
              <.icon name="hero-check" class="h-5 w-5" />
            </span>
          </li>
        </ul>
      </div>
      <!-- end team filter -->
    </div>
    """
  end

  def handle_event("select_team", %{"team_id" => team_id}, socket) do
    params =
      (socket.assigns.uri.query || "")
      |> URI.decode_query()
      |> Map.put("team_id", team_id)
      |> URI.encode_query()

    {:noreply, push_patch(socket, to: "#{socket.assigns.uri.path}?#{params}")}
  end

  def handle_event("select_team", _no_team_params, socket) do
    params =
      (socket.assigns.uri.query || "")
      |> URI.decode_query()
      |> Map.delete("team_id")
      |> URI.encode_query()

    {:noreply, push_patch(socket, to: "#{socket.assigns.uri.path}?#{params}")}
  end

  def handle_event("filter_teams", %{"filter_teams" => filter}, socket) do
    filtered_teams =
      Enum.filter(socket.assigns.teams, fn team ->
        String.contains?(String.downcase(team.name || ""), String.downcase(filter))
      end)

    {:noreply, assign(socket, :filtered_teams, filtered_teams)}
  end
end
