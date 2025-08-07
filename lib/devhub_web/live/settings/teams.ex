defmodule DevhubWeb.Live.Settings.Teams do
  @moduledoc false
  use DevhubWeb, :live_view

  import DevhubWeb.Components.SettingsTabs

  alias Devhub.Users

  def mount(_params, _session, socket) do
    %{organization: organization} = socket.assigns
    organization_user = Devhub.Repo.preload(socket.assigns.organization_user, :teams)

    teams = Users.list_teams(organization.id)

    socket
    |> assign(
      page_title: "Devhub",
      organization_user: organization_user,
      teams: teams
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header>
        <:header>
          <.settings_tabs active_path={@active_path} organization_user={@organization_user} />
        </:header>
        <:actions>
          <.button
            :if={@permissions.super_admin or @permissions.manager}
            phx-click={show_modal("add-team")}
          >
            Add team
          </.button>
        </:actions>
      </.page_header>

      <ul role="list" class="divide-alpha-8 bg-surface-1 divide-y rounded-lg">
        <li :for={team <- @teams} class="flex items-center justify-between gap-x-4 p-4">
          <p class="font-bold">{team.name}</p>
          <.dropdown
            :if={@permissions.super_admin or @permissions.manager}
            id={"team-#{team.id}-options"}
          >
            <:trigger>
              <div class="bg-alpha-4 rounded-md p-1">
                <.icon name="hero-ellipsis-vertical" class="size-5 text-gray-900" />
              </div>
            </:trigger>
            <div class="divide-alpha-8 bg-surface-2 absolute top-2 -right-10 w-48 divide-y rounded px-4 py-3 ring-1 ring-gray-100 ring-opacity-5">
              <div
                class="w-full cursor-pointer px-4 py-3"
                phx-click={show_modal("update-team-#{team.id}")}
              >
                <p class="mb-1 text-sm">Edit</p>
              </div>
              <div>
                <button
                  data-confirm={"Are you sure you want to delete #{team.name}?"}
                  phx-click="delete_team"
                  phx-value-id={team.id}
                  class="px-4 py-3 text-red-500"
                >
                  Delete
                </button>
              </div>
            </div>
          </.dropdown>

          <.modal id={"update-team-#{team.id}"}>
            <div>
              <div class="mb-2 text-center">
                <h3 class="text-base font-semibold text-gray-900" id="modal-title">
                  Update team
                </h3>
              </div>
            </div>
            <.form
              :let={f}
              for={to_form(%{"name" => team.name})}
              phx-submit={JS.push("update_team") |> hide_modal("update-team-#{team.id}")}
              data-testid="update-team-form"
            >
              <input type="hidden" name="team_id" value={team.id} />
              <.input label="Name" field={f[:name]} />
              <div class="mt-4 grid grid-cols-2 gap-4">
                <.button
                  type="button"
                  variant="secondary"
                  phx-click={JS.exec("data-cancel", to: "#update-team-#{team.id}")}
                  aria-label={gettext("close")}
                >
                  Cancel
                </.button>
                <.button type="submit" variant="primary">Save</.button>
              </div>
            </.form>
          </.modal>
        </li>
      </ul>

      <.modal id="add-team">
        <.form
          for={%{}}
          phx-submit={JS.push("add_team") |> hide_modal("add-team")}
          class="focus-on-show"
          data-testid="add-team-form"
        >
          <.input label="Team name" name="name" value="" />
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#add-team")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit" variant="primary">Save</.button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  def handle_event("add_team", %{"name" => name}, socket) do
    permissions = socket.assigns.permissions

    if permissions.super_admin or permissions.manager do
      {:ok, team} = Users.create_team(name, socket.assigns.organization)
      teams = Enum.sort_by([team | socket.assigns.teams], & &1.name)

      {:noreply, assign(socket, teams: teams)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_team", params, socket) do
    permissions = socket.assigns.permissions

    if permissions.super_admin or permissions.manager do
      index = Enum.find_index(socket.assigns.teams, &(&1.id == params["team_id"]))
      {team, teams} = List.pop_at(socket.assigns.teams, index)

      {:ok, team} = Users.update_team(team, params)
      teams = List.insert_at(teams, index, team)

      {:noreply, assign(socket, teams: teams)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_team", %{"id" => id}, socket) do
    permissions = socket.assigns.permissions

    if permissions.super_admin or permissions.manager do
      team = Enum.find(socket.assigns.teams, &(&1.id == id))
      {:ok, _team} = Users.delete_team(team)

      teams = Enum.filter(socket.assigns.teams, &(&1.id != id))

      {:noreply, assign(socket, teams: teams)}
    else
      {:noreply, socket}
    end
  end
end
