defmodule DevhubWeb.Live.Settings.Account do
  @moduledoc false
  use DevhubWeb, :live_view

  import DevhubWeb.Components.SettingsTabs

  alias Devhub.Users
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.User

  require Logger

  def mount(_params, _session, socket) do
    timezones = Enum.map(Tzdata.zone_list(), &%{id: &1, name: String.replace(&1, "_", " ")})
    user_changeset = User.changeset(socket.assigns.user, %{})

    socket
    |> assign(
      page_title: "Devhub",
      timezones: timezones,
      filtered_timezones: timezones,
      user_changeset: user_changeset,
      passkeys: Users.get_passkeys(socket.assigns.user)
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
      </.page_header>

      <div class="space-y-4">
        <div
          :if={@permissions.super_admin}
          class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7"
        >
          <div class="col-span-2">
            <h2 class="text-base font-semibold text-gray-900">Account settings</h2>
            <p class="text-alpha-64 mt-1 text-sm">
              Update settings for your entire account (only super admins can manage this section).
            </p>
          </div>

          <div class="col-span-5 flex flex-col gap-y-4">
            <.form
              :let={f}
              for={Organization.update_changeset(@organization, %{})}
              phx-change="update_organization"
              class="flex w-full flex-col gap-y-4"
            >
              <div :if={Devhub.cloud_hosted?()} class="flex flex-col gap-y-2">
                <.input
                  name="domain"
                  type="text"
                  phx-debounce="300"
                  label="Domain"
                  value={Application.get_env(:devhub, DevhubWeb.Endpoint)[:url][:host]}
                  disabled={true}
                />
                <span class="text-alpha-64 text-xs">
                  Reach out to support@devhub.tools to change your domain.
                </span>
              </div>
              <.input
                name="version"
                type="text"
                phx-debounce="300"
                label="Version"
                value={System.get_env("APP_VERSION")}
                disabled={true}
              />
              <.input field={f[:name]} type="text" phx-debounce="300" label="Account name" />
              <.input
                field={f[:proxy_password_expiration_seconds]}
                type="number"
                label="Proxy password expiration"
                tooltip="The number of seconds a proxy password is valid for."
              />
              <.input field={f[:mfa_required]} type="toggle" label="require mfa" />
            </.form>
          </div>
        </div>

        <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7">
          <div class="col-span-2">
            <h2 class="text-base font-semibold text-gray-900">Personal settings</h2>
            <p class="text-alpha-64 mt-1 text-sm">
              Customize your personal settings, such as your name and timezone.
            </p>
          </div>

          <div class="col-span-5 flex flex-col gap-y-4">
            <div>
              <.label>Timezone</.label>
              <.dropdown_with_search
                filtered_objects={@filtered_timezones}
                filter_action="filter_timezones"
                friendly_action_name="Timezone search"
                selected_object_name={String.replace(@user.timezone, "_", " ")}
                select_action="select_timezone"
              />
            </div>
            <.form
              :let={f}
              for={@user_changeset}
              phx-change="update_user"
              class="flex w-full flex-col gap-y-4"
            >
              <.input field={f[:name]} type="text" phx-debounce="300" label="Name" />
            </.form>
          </div>
        </div>

        <div
          id="passkey-settings"
          phx-hook="Passkey"
          class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7"
        >
          <div class="col-span-2">
            <h2 class="text-base font-semibold text-gray-900">MFA</h2>
            <p class="text-alpha-64 mt-1 text-sm">
              We support passkeys for MFA, which can be used during login and to approve requests.
            </p>
          </div>

          <div class="col-span-5 flex flex-col gap-y-4">
            <div
              :for={passkey <- @passkeys}
              class="ring-alpha-16 flex w-full items-center justify-between rounded p-4 text-gray-600 ring-1"
            >
              <span class="flex items-center gap-x-1">
                <img src="/images/fido.svg" class="size-6" />Passkey setup on
                <format-date date={passkey.inserted_at} />
              </span>
              <.button variant="destructive-text" phx-click="remove_passkey" phx-value-id={passkey.id}>
                Remove
              </.button>
            </div>
            <.button variant="outline" class="w-fit" phx-click="start_passkey_registration">
              Setup Passkey
            </.button>
          </div>
        </div>

        <.live_component
          module={DevhubWeb.Components.Products}
          id="products"
          organization={@organization}
          features={["Dev Portal", "GitHub integration", "Linear integration"]}
        />
      </div>
    </div>
    """
  end

  def handle_event("update_organization", %{"organization" => params}, socket) do
    if socket.assigns.permissions.super_admin do
      params = Map.take(params, ["name", "mfa_required", "proxy_password_expiration_seconds"])
      {:ok, organization} = Users.update_organization(socket.assigns.organization, params)

      {:noreply, assign(socket, organization: organization)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_user", %{"user" => params}, socket) do
    socket.assigns.user
    |> Users.update_user(%{name: params["name"]})
    |> case do
      {:ok, user} ->
        changeset = User.changeset(user, %{})
        socket |> assign(user: user, user_changeset: changeset) |> noreply()

      {:error, changeset} ->
        socket |> assign(user_changeset: changeset) |> noreply()
    end
  end

  def handle_event("filter_timezones", %{"name" => filter}, socket) do
    filtered_timezones =
      Enum.filter(socket.assigns.timezones, fn timezone ->
        String.contains?(String.downcase(timezone.name || ""), String.downcase(filter))
      end)

    {:noreply, assign(socket, :filtered_timezones, filtered_timezones)}
  end

  def handle_event("select_timezone", %{"id" => timezone}, socket) do
    {:ok, user} = Users.update_user(socket.assigns.user, %{timezone: timezone})

    {:noreply,
     assign(socket,
       user: user,
       filtered_timezones: socket.assigns.timezones
     )}
  end

  def handle_event("clear_filter", _params, socket) do
    socket
    |> assign(filtered_timezones: socket.assigns.timezones)
    |> noreply()
  end

  def handle_event("start_passkey_registration", _params, socket) do
    challenge = Wax.new_registration_challenge()

    socket
    |> assign(challenge: challenge)
    |> push_event("start_passkey_registration", %{
      challenge: Base.encode64(challenge.bytes),
      attestation: challenge.attestation,
      userId: socket.assigns.user.id,
      displayName: socket.assigns.user.email,
      rpId: challenge.rp_id
    })
    |> noreply()
  end

  def handle_event("register_passkey", %{"type" => "public-key"} = params, socket) do
    challenge = socket.assigns.challenge
    socket = assign(socket, challenge: nil)

    with {:ok, attestation_object} <- Base.decode64(params["attestationObject"]),
         {:ok, {authenticator_data, _result}} <- Wax.register(attestation_object, params["clientDataJSON"], challenge),
         aaguid = Wax.AuthenticatorData.get_aaguid(authenticator_data),
         {:ok, passkey} <-
           Users.register_passkey(socket.assigns.user, %{
             raw_id: params["rawId"],
             public_key: :erlang.term_to_binary(authenticator_data.attested_credential_data.credential_public_key),
             aaguid: aaguid
           }) do
      passkeys =
        socket.assigns.passkeys
        |> Enum.reverse()
        |> List.insert_at(0, passkey)
        |> Enum.reverse()

      socket
      |> assign(:passkeys, passkeys)
      |> put_flash(:info, "Passkey registered")
      |> noreply()
    else
      error ->
        Logger.error("Failed to register passkey: #{inspect(error)}")

        socket
        |> put_flash(:error, "Failed to register passkey")
        |> noreply()
    end
  end

  def handle_event("remove_passkey", %{"id" => passkey_id}, socket) do
    index = Enum.find_index(socket.assigns.passkeys, &(&1.id == passkey_id))
    passkey = Enum.at(socket.assigns.passkeys, index)

    case Users.remove_passkey(socket.assigns.user, passkey) do
      {:ok, _passkey} ->
        passkeys = List.delete_at(socket.assigns.passkeys, index)

        socket
        |> assign(:passkeys, passkeys)
        |> put_flash(:info, "Passkey removed")
        |> noreply()

      _error ->
        socket
        |> put_flash(:error, "Failed to remove passkey")
        |> noreply()
    end
  end
end
