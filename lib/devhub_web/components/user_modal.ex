defmodule DevhubWeb.Components.UserModal do
  @moduledoc false
  use DevhubWeb, :html

  alias DevhubPrivateWeb.Live.Settings.Users, as: PrivateUsers

  def user_modal(assigns) do
    ~H"""
    <div class="text-sm">
      <.modal id="user-modal" show={true} on_cancel={JS.push("hide_user_modal")}>
        <.invite :if={@invite} />

        <.manage_teams :if={@manage_teams} teams={@teams} user={@user} />

        <div
          :if={not @invite and not @manage_teams and not @manage_roles}
          class="flex flex-col gap-y-4"
        >
          <div class="flex items-center justify-between">
            <.user_block :if={@user.id} user={@user} />
            <div :if={is_nil(@user.id)}>
              <.button phx-click="start_invite">Invite user</.button>
            </div>
            <.button
              :if={is_nil(@user.organization_user.archived_at)}
              type="button"
              variant="destructive-text"
              phx-click="archive"
            >
              Archive
            </.button>
            <.button
              :if={not is_nil(@user.organization_user.archived_at)}
              type="button"
              variant="text"
              phx-click="unarchive"
            >
              Unarchive
            </.button>
          </div>
          <.button
            :if={Code.ensure_loaded?(PrivateUsers) and not @user.has_license and not is_nil(@user.id)}
            phx-click="assign_license"
            phx-disable-with="Adding..."
          >
            Assign license
          </.button>
          <span
            :if={
              Code.ensure_loaded?(PrivateUsers) and not @user.has_license and not is_nil(@user.id) and
                @available_seats == 0
            }
            class="text-alpha-64 mx-auto -mt-2 text-xs"
          >
            You will be charged for an additional seat.
          </span>
          <div>
            <h3 class="text-alpha-64 text-xs uppercase">
              GitHub user
            </h3>
            <.dropdown_with_search
              filtered_objects={@filtered_github_users}
              filter_action="filter_github_users"
              friendly_action_name="GitHub user search"
              selected_object_name={@user.github_username}
              select_action="select_github_user"
            />
          </div>
          <div>
            <h3 class="text-alpha-64 text-xs uppercase">
              Linear user
            </h3>
            <.dropdown_with_search
              filter_action="filter_linear_users"
              filtered_objects={@filtered_linear_users}
              friendly_action_name="Linear user search"
              selected_object_name={@user.linear_username}
              select_action="select_linear_user"
            />
          </div>
          <.form :let={f} for={@changeset} phx-change="update_organization_user">
            <.input
              field={f[:legal_name]}
              label="Name on OOO Calendar (if different)"
              phx-debounce="300"
            />
            <.inputs_for :let={permissions} :if={@permissions.super_admin} field={f[:permissions]}>
              <h3 class="text-alpha-64 border-alpha-8 mt-6 mb-3 border-b pb-2 text-xs uppercase">
                Permissions
              </h3>
              <div class="flex flex-col gap-y-2">
                <.input type="checkbox" field={permissions[:super_admin]} label="Super admin" />
                <.input type="checkbox" field={permissions[:manager]} label="Manager" />
                <.input type="checkbox" field={permissions[:billing_admin]} label="Billing admin" />
              </div>
            </.inputs_for>
          </.form>

          <div :if={Code.ensure_loaded?(PrivateUsers)}>
            <div class="border-alpha-8 flex items-center justify-between border-b pb-2">
              <h3 class="text-alpha-64 text-xs uppercase">Roles</h3>
              <.button type="button" variant="text" phx-click="manage_roles" size="sm">
                Manage roles
              </.button>
            </div>
            <div class="flex items-center justify-between">
              <div class="py-4 text-sm">{@user.roles}</div>
            </div>
          </div>

          <div>
            <div class="border-alpha-8 flex items-center justify-between border-b pb-2">
              <h3 class="text-alpha-64 text-xs uppercase">Teams</h3>
              <.button type="button" variant="text" phx-click="manage_teams" size="sm">
                Manage teams
              </.button>
            </div>
            <div class="flex items-center justify-between">
              <div class="py-4 text-sm">{@user.teams}</div>
            </div>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  defp invite(assigns) do
    ~H"""
    <div>
      <div class="mb-6 text-center">
        <h3 class="text-base font-semibold text-gray-900">
          Invite user
        </h3>
      </div>
      <.form :let={f} for={%{}} phx-submit="send_invite">
        <div class="flex flex-col gap-y-4">
          <.input id="imported-user-name" field={f[:name]} label="Name" />
          <.input id="imported-user-email" field={f[:email]} label="Email" />
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button type="button" variant="secondary" phx-click="cancel_invite">Cancel</.button>
            <.button>Invite</.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  defp manage_teams(assigns) do
    ~H"""
    <div>
      <h3 class="text-alpha-64 border-alpha-8 border-b pb-2 text-xs uppercase">Teams</h3>
      <div class="divide-alpha-8 divide-y">
        <div :for={team <- @teams}>
          <div class="flex items-center justify-between py-4">
            <div class="sm:flex sm:items-start">
              <div class="text-sm">{team.name}</div>
            </div>
            <div class="mt-4 sm:mt-0 sm:ml-6 sm:flex-shrink-0">
              <button
                :if={String.contains?(@user.team_ids, team.id)}
                type="button"
                phx-click="remove_from_team"
                phx-value-team_id={team.id}
              >
                <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                  <.icon name="hero-x-mark-mini" class="h-5 w-5 align-bottom text-gray-900" />
                </div>
              </button>
              <.button
                :if={not String.contains?(@user.team_ids, team.id)}
                type="button"
                variant="text"
                phx-click="add_to_team"
                phx-value-team_id={team.id}
              >
                Add to team
              </.button>
            </div>
          </div>
        </div>
      </div>

      <div class="my-2 flex justify-between">
        <.button type="button" variant="primary" phx-click="done_managing_teams">
          Done
        </.button>
        <.link_button
          :if={@teams == []}
          href={~p"/settings/teams"}
          variant="text"
          data-testid="create-team"
        >
          <p>Create a team</p>
        </.link_button>
      </div>
    </div>
    """
  end
end
