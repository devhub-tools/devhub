defmodule DevhubWeb.Live.Settings.Users do
  @moduledoc false
  use DevhubWeb, :live_view

  import DevhubWeb.Components.SettingsTabs
  import DevhubWeb.Components.UserModal

  alias Devhub.Permissions
  alias Devhub.Users
  alias Devhub.Users.Schemas.OrganizationUser
  alias DevhubPrivateWeb.Live.Settings.Users, as: PrivateUsers

  def mount(_params, _session, socket) do
    %{organization: organization} = socket.assigns

    teams = Users.list_teams(organization.id)

    socket
    |> assign(
      page_title: "Devhub",
      teams: teams,
      invite: false,
      manage_roles: false,
      manage_teams: false,
      filtered_linear_users: [],
      filtered_github_users: [],
      selected_user: nil
    )
    |> assign_new(:assigned_seats, fn -> [] end)
    |> fetch_users()
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header>
        <:header>
          <.settings_tabs active_path={@active_path} organization_user={@organization_user} />
        </:header>
      </.page_header>
      <div>
        <.page_header>
          <:header>
            <div class="flex min-w-0 gap-x-4">
              <div class="min-w-0 flex-auto">
                <p class="text-2xl font-bold text-gray-900">
                  Users
                </p>
                <%= if Code.ensure_loaded?(PrivateUsers) do %>
                  <p class="mt-1 flex text-xs text-gray-600">
                    {length(@assigned_seats)} / {@organization.license.included_seats +
                      @organization.license.extra_seats} seats used
                    <span :if={Permissions.can?(:manage_billing, @organization_user)}>
                      &nbsp;-
                      <.link navigate="/settings/billing" class="text-blue-800">
                        Add seats
                      </.link>
                    </span>
                  </p>
                <% end %>
              </div>
            </div>
          </:header>
          <:actions>
            <.button phx-click={show_modal("invite-user")}>
              Invite User
            </.button>
          </:actions>
        </.page_header>

        <ul role="list" class="divide-alpha-8 bg-surface-1 mb-4 divide-y rounded-lg">
          <li
            :for={user <- @login_users}
            class={[
              "flex items-center justify-between p-4",
              not is_nil(user.organization_user.archived_at) && "opacity-40"
            ]}
          >
            <div class="grid w-full grid-cols-6 items-center">
              <div class="col-span-2 flex flex-col">
                <span>{user.name}</span>
                <span class="text-alpha-64 text-sm">{user.email}</span>
              </div>
              <div class="col-span-2 flex items-center gap-y-1 pr-6">
                <div :if={not user.has_license}>
                  <span class="bg-yellow-600/10 ring-yellow-600/20 inline-flex items-center rounded-md px-2 py-1 text-xs font-medium text-yellow-600 ring-1 ring-inset">
                    No license assigned
                  </span>
                </div>
                <div :if={user.pending and user.has_license}>
                  <span class="bg-gray-600/10 ring-gray-600/20 inline-flex items-center rounded-md px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset">
                    Pending invite
                  </span>
                </div>
                <div :if={user.has_license and not user.pending}>{user.teams}</div>
              </div>
              <div>
                <span :if={user.passkeys > 0}>
                  <.icon name="hero-check-mini" class="size-4 text-green-500" /> MFA
                </span>
              </div>
              <div class="flex items-center justify-end gap-x-2 pr-6 text-xs">
                <.link
                  :if={user.github_user_id}
                  navigate={~p"/portal/metrics/devs/#{user.github_user_id}"}
                >
                  <.icon name="devhub-github" class="size-6" />
                </.link>
                <div :if={user.linear_user_id}>
                  <.icon name="devhub-linear" class="size-6" />
                </div>
              </div>
            </div>
            <button
              class="bg-alpha-4 rounded-md p-1"
              phx-click="show_user_modal"
              phx-value-id={user.modal_id}
            >
              <.icon name="hero-ellipsis-vertical" class="size-5 text-gray-900" />
            </button>
          </li>
        </ul>

        <%= if not Enum.empty?(@other_licensed_users) do %>
          <.page_header>
            <:header>
              <p class="text-2xl font-bold text-gray-900">
                Other licensed users
              </p>
            </:header>
          </.page_header>

          <ul role="list" class="divide-alpha-8 bg-surface-1 mb-6 divide-y rounded-lg">
            <li :for={user <- @other_licensed_users} class="flex items-center justify-between p-4">
              <div class="grid w-full grid-cols-6 items-center">
                <div class="col-span-2 flex flex-col">
                  <span>{user.external_id}</span>
                  <span class="text-alpha-64 text-sm">{user.provider}</span>
                </div>
              </div>
              <.button
                class="bg-alpha-4 rounded-md p-1"
                phx-click="revoke_license"
                phx-value-provider={user.provider}
                phx-value-external_id={user.external_id}
                variant="neutral"
              >
                Revoke
              </.button>
            </li>
          </ul>
        <% end %>

        <.page_header :if={not Enum.empty?(@imported_users)}>
          <:header>
            <p class="text-2xl font-bold text-gray-900">
              Imported users
            </p>
          </:header>
        </.page_header>

        <ul role="list" class="divide-alpha-8 bg-surface-1 divide-y rounded-lg">
          <li
            :for={user <- @imported_users}
            class={[
              "flex items-center justify-between p-4",
              not is_nil(user.organization_user.archived_at) && "opacity-40"
            ]}
          >
            <div class="grid w-full grid-cols-5 items-center">
              <div class="col-span-2 flex flex-col">
                <span>{user.name}</span>
                <span class="text-alpha-64 text-sm">{user.email}</span>
              </div>
              <div class="col-span-2 flex items-center gap-y-1 pr-6">
                <div>{user.teams}</div>
              </div>
              <div class="flex items-center justify-end gap-y-1 pr-6 text-xs">
                <.link
                  :if={user.github_user_id}
                  navigate={~p"/portal/metrics/devs/#{user.github_user_id}"}
                >
                  <.icon name="devhub-github" class="size-6" />
                </.link>
                <div :if={user.linear_user_id}>
                  <.icon name="devhub-linear" class="size-6" />
                </div>
              </div>
            </div>
            <button
              class="bg-alpha-4 rounded-md p-1"
              phx-click="show_user_modal"
              phx-value-id={user.modal_id}
            >
              <.icon name="hero-ellipsis-vertical" class="size-5" />
            </button>
          </li>
        </ul>

        <.user_modal
          :if={@selected_user}
          changeset={@changeset}
          filtered_github_users={@filtered_github_users}
          filtered_linear_users={@filtered_linear_users}
          invite={@invite}
          manage_roles={@manage_roles}
          manage_teams={@manage_teams}
          teams={@teams}
          roles={assigns[:roles] || []}
          user={@selected_user}
          permissions={@permissions}
          available_seats={assigns[:available_seats] || 0}
        />
      </div>
    </div>

    <.modal id="invite-user">
      <div class="mb-6 text-center">
        <h3 class="text-base font-semibold text-gray-900">
          Invite user
        </h3>
      </div>
      <.form
        :let={f}
        for={%{}}
        phx-submit={JS.push("invite_new_user") |> hide_modal("invite-user")}
        data-testid="invite_new_user_form"
      >
        <div class="flex flex-col gap-y-4">
          <.input field={f[:name]} label="Name" />
          <.input field={f[:email]} label="Email" />
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#invite-user")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button>Invite</.button>
          </div>
        </div>
      </.form>
    </.modal>
    """
  end

  def handle_event("clear_filter", _params, socket) do
    socket
    |> assign(
      filtered_linear_users: socket.assigns.linear_users,
      filtered_github_users: socket.assigns.github_users
    )
    |> noreply()
  end

  def handle_event("show_user_modal", %{"id" => id}, socket) do
    selected_user = Enum.find(socket.assigns.users, &(&1.modal_id == id))

    {:ok, organization_user} =
      if is_binary(selected_user.organization_user.id) do
        {:ok, selected_user.organization_user}
      else
        Users.create_organization_user(%{
          organization_id: socket.assigns.organization.id,
          user_id: selected_user.id,
          linear_user_id: selected_user.linear_user_id,
          github_user_id: selected_user.github_user_id,
          permissions: %{}
        })
      end

    socket
    |> fetch_users()
    |> then(&assign(&1, filtered_linear_users: &1.assigns.linear_users))
    |> then(&assign(&1, filtered_github_users: &1.assigns.github_users))
    |> assign(selected_user: %{selected_user | organization_user: organization_user})
    |> select_user()
    |> noreply()
  end

  def handle_event("hide_user_modal", _params, socket) do
    socket |> assign(selected_user: nil, invite: false) |> noreply()
  end

  def handle_event("update_organization_user", %{"organization_user" => params}, socket) do
    params = Map.take(params, ["legal_name", "permissions"])

    {:ok, _organization_user} =
      Users.update_organization_user(socket.assigns.selected_user.organization_user, params)

    socket
    |> fetch_users()
    |> select_user()
    |> noreply()
  end

  def handle_event("archive", _params, %{assigns: %{selected_user: %{organization_user: %{user_id: nil}}}} = socket) do
    case Users.update_organization_user(socket.assigns.selected_user.organization_user, %{
           archived_at: DateTime.utc_now()
         }) do
      {:ok, _organization_user} ->
        socket
        |> fetch_users()
        |> select_user()
        |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to archive user") |> noreply()
    end
  end

  if Code.ensure_loaded?(PrivateUsers) do
    def handle_event("archive", _params, socket) do
      PrivateUsers.archive(socket)
    end
  else
    def handle_event("archive", _params, socket) do
      Users.update_organization_user(socket.assigns.selected_user.organization_user, %{
        archived_at: DateTime.utc_now()
      })

      socket
      |> fetch_users()
      |> select_user()
      |> noreply()
    end
  end

  def handle_event("unarchive", _params, socket) do
    {:ok, _organization_user} =
      Users.update_organization_user(socket.assigns.selected_user.organization_user, %{archived_at: nil})

    socket
    |> fetch_users()
    |> select_user()
    |> noreply()
  end

  def handle_event("add_to_team", %{"team_id" => team_id}, socket) do
    user = socket.assigns.selected_user
    team = Enum.find(socket.assigns.teams, &(&1.id == team_id))
    {:ok, _team_member} = Users.add_to_team(user.organization_user.id, team.id)

    socket
    |> fetch_users()
    |> select_user()
    |> noreply()
  end

  def handle_event("remove_from_team", %{"team_id" => team_id}, socket) do
    user = socket.assigns.selected_user
    team = Enum.find(socket.assigns.teams, &(&1.id == team_id))
    Users.remove_from_team(user.organization_user.id, team.id)

    socket
    |> fetch_users()
    |> select_user()
    |> noreply()
  end

  def handle_event("filter_linear_users", %{"name" => filter}, socket) do
    filtered_users =
      Enum.filter(socket.assigns.linear_users, fn user ->
        String.contains?(String.downcase(user.name || ""), String.downcase(filter))
      end)

    {:noreply, assign(socket, :filtered_linear_users, filtered_users)}
  end

  def handle_event("filter_github_users", %{"name" => filter}, socket) do
    filtered_users =
      Enum.filter(socket.assigns.github_users, fn user ->
        String.contains?(String.downcase(user.name || ""), String.downcase(filter))
      end)

    {:noreply, assign(socket, :filtered_github_users, filtered_users)}
  end

  def handle_event("select_linear_user", %{"id" => linear_user_id}, socket) do
    selected_user = socket.assigns.selected_user

    linear_user =
      Enum.find(socket.assigns.users, fn user -> user.linear_user_id == linear_user_id end)

    # make sure linear user id is set
    linear_organization_user = %{linear_user.organization_user | linear_user_id: linear_user_id}

    case Users.merge(selected_user.organization_user, linear_organization_user) do
      {:ok, _organization_user} ->
        socket
        |> fetch_users()
        |> select_user()
        |> then(&assign(&1, filtered_linear_users: &1.assigns.linear_users))
        |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to merge users") |> noreply()
    end
  end

  def handle_event("select_github_user", %{"id" => github_user_id}, socket) do
    selected_user = socket.assigns.selected_user

    github_user =
      Enum.find(socket.assigns.users, fn user -> user.github_user_id == github_user_id end)

    # make sure github user id is set
    github_organization_user = %{github_user.organization_user | github_user_id: github_user_id}

    case Users.merge(selected_user.organization_user, github_organization_user) do
      {:ok, _organization_user} ->
        socket
        |> fetch_users()
        |> select_user()
        |> then(&assign(&1, filtered_github_users: &1.assigns.github_users))
        |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to merge users") |> noreply()
    end
  end

  def handle_event("start_invite", _params, socket) do
    socket |> assign(invite: true) |> noreply()
  end

  def handle_event("cancel_invite", _params, socket) do
    socket |> assign(invite: false) |> noreply()
  end

  def handle_event("send_invite", %{"name" => name, "email" => email}, socket) do
    selected_user = socket.assigns.selected_user

    case Users.invite_user(selected_user.organization_user, name, email) do
      {:ok, _organization_user} ->
        socket
        |> fetch_users()
        |> select_user()
        |> assign(invite: false)
        |> put_flash(:info, "User invite created")
        |> noreply()

      _error ->
        socket
        |> put_flash(:error, "Failed to invite user")
        |> noreply()
    end
  end

  def handle_event("invite_new_user", %{"name" => name, "email" => email}, socket) do
    with {:ok, organization_user} <-
           Users.create_organization_user(%{organization_id: socket.assigns.organization.id, permissions: %{}}),
         {:ok, _organization_user} <- Users.invite_user(organization_user, name, email) do
      socket
      |> push_navigate(to: ~p"/settings/users")
      |> put_flash(:info, "User invite created")
      |> noreply()
    else
      _error ->
        socket
        |> put_flash(:error, "Failed to invite user")
        |> noreply()
    end
  end

  def handle_event("manage_teams", _params, socket) do
    socket |> assign(manage_teams: true) |> noreply()
  end

  def handle_event("done_managing_teams", _params, socket) do
    socket |> assign(manage_teams: false) |> noreply()
  end

  if Code.ensure_loaded?(PrivateUsers) do
    defdelegate handle_event(event, params, socket), to: PrivateUsers
  end

  defp fetch_users(socket) do
    users =
      socket.assigns.organization.id
      |> Users.list_users()
      |> Enum.map(fn user ->
        user
        |> Map.put(:modal_id, Ecto.UUID.generate())
        |> Map.put(
          :has_license,
          user.license_ref in socket.assigns.assigned_seats or not Code.ensure_loaded?(PrivateUsers)
        )
      end)

    login_users = Enum.reject(users, fn user -> is_nil(user.organization_user.user_id) end)
    imported_users = Enum.filter(users, fn user -> is_nil(user.organization_user.user_id) end)

    other_licensed_users =
      socket.assigns.assigned_seats
      |> Enum.reject(fn seat ->
        Enum.any?(login_users, &(&1.license_ref == seat))
      end)
      |> Enum.map(fn seat ->
        [provider, external_id] = String.split(seat, ":", parts: 2)
        %{provider: provider, external_id: external_id}
      end)

    linear_users =
      users
      |> Enum.filter(fn user -> not is_nil(user.linear_user_id) end)
      |> Enum.map(&%{id: &1.linear_user_id, name: &1.linear_username})

    github_users =
      users
      |> Enum.filter(fn user -> not is_nil(user.github_user_id) end)
      |> Enum.map(&%{id: &1.github_user_id, name: &1.github_username})

    assign(socket,
      users: users,
      login_users: login_users,
      other_licensed_users: other_licensed_users,
      imported_users: imported_users,
      linear_users: linear_users,
      github_users: github_users
    )
  end

  defp select_user(socket) do
    user =
      Enum.find(socket.assigns.users, &(&1.organization_user.id == socket.assigns.selected_user.organization_user.id))

    changeset = OrganizationUser.changeset(user.organization_user, %{})

    assign(socket, selected_user: user, changeset: changeset)
  end
end
