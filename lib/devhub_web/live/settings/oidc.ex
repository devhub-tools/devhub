defmodule DevhubWeb.Live.Settings.OIDC do
  @moduledoc false
  use DevhubWeb, :live_view

  import DevhubWeb.Components.SettingsTabs

  alias Devhub.Users
  alias Devhub.Users.OIDC

  def mount(_params, _session, socket) do
    oidc_changeset =
      case Users.get_oidc_config([organization_id: socket.assigns.organization.id], false) do
        {:ok, oidc, _config} ->
          OIDC.changeset(oidc, %{})

        {:error, :oidc_config_not_found} ->
          OIDC.changeset(%OIDC{}, %{})
      end

    socket
    |> assign(
      page_title: "Devhub",
      oidc_changeset: oidc_changeset
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.form :let={f} for={@oidc_changeset} phx-submit="update_oidc">
        <.page_header>
          <:header>
            <.settings_tabs active_path={@active_path} organization_user={@organization_user} />
          </:header>
          <:actions>
            <.button type="submit">
              Update
            </.button>
          </:actions>
        </.page_header>

        <div class="bg-surface-1 rounded-lg p-4">
          <dl class="divide-alpha-8 space-y-4 divide-y">
            <div class="flex items-center">
              <dt class="text-alpha-64 sm:w-64 sm:flex-none sm:pr-6">Login URI</dt>
              <dd class="mt-1 flex justify-between gap-x-6 sm:mt-0 sm:flex-auto">
                {"#{DevhubWeb.Endpoint.url()}/auth/oidc"}
              </dd>
            </div>
            <div class="flex items-center pt-4">
              <dt class="text-alpha-64 sm:w-64 sm:flex-none sm:pr-6">Redirect URI</dt>
              <dd class="mt-1 flex justify-between gap-x-6 sm:mt-0 sm:flex-auto">
                {"#{DevhubWeb.Endpoint.url()}/auth/oidc/callback"}
              </dd>
            </div>
            <div class="pt-4 sm:flex"></div>
          </dl>

          <div class="flex flex-col gap-y-4">
            <.input
              field={f[:discovery_document_uri]}
              label="Discovery Document URI"
              phx-debounce="300"
            />
            <.input field={f[:client_id]} label="Client ID" phx-debounce="300" />
            <.input
              type="password"
              field={f[:client_secret]}
              value=""
              label="Client secret"
              phx-debounce="300"
            />
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("update_oidc", %{"oidc" => params}, socket) do
    oidc = socket.assigns.oidc_changeset.data

    params =
      if params["client_secret"] == "" do
        Map.delete(params, "client_secret")
      else
        params
      end

    params = Map.put(params, "organization_id", socket.assigns.organization.id)

    case Users.insert_or_update_oidc(oidc, params) do
      {:ok, oidc} ->
        {:noreply, assign(socket, oidc_changeset: OIDC.changeset(oidc, %{}))}

      _error ->
        socket
        |> put_flash(:error, "Failed to update OIDC.")
        |> noreply()
    end
  end
end
