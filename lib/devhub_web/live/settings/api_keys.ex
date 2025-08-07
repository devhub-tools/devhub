defmodule DevhubWeb.Live.Settings.ApiKeys do
  @moduledoc false
  use DevhubWeb, :live_view

  import DevhubWeb.Components.SettingsTabs

  alias Devhub.ApiKeys
  alias Devhub.Utils

  def mount(_params, _session, socket) do
    api_keys = ApiKeys.list(socket.assigns.organization)

    socket
    |> assign(
      page_title: "Devhub",
      api_keys: api_keys,
      editing_api_key: nil,
      api_key_form: to_form(%{})
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
          <.button type="button" phx-click={show_modal("add-api-key")}>
            New API key
          </.button>
        </:actions>
      </.page_header>

      <ul role="list" class="divide-alpha-8 bg-surface-1 divide-y rounded-lg">
        <li :for={api_key <- @api_keys} class="flex items-center justify-between gap-x-6 p-4">
          <%= if Map.has_key?(api_key, :token) do %>
            <div class="w-full">
              <div class="text-xs text-gray-600">
                Save your API key securely, you will not be able to retrieve it again.
              </div>
              <copy-text value={api_key.token} />
            </div>
          <% else %>
            <div class="font-bold">{api_key.name}</div>

            <div class="flex gap-x-4">
              <.button
                type="button"
                phx-click={
                  show_modal("edit-api-key-#{api_key.id}")
                  |> JS.push("edit_api_key", value: %{id: api_key.id})
                }
                variant="text"
                data-testid="edit-api-key"
              >
                Edit
              </.button>

              <.button
                type="button"
                phx-click="revoke_api_key"
                phx-value-id={api_key.id}
                variant="destructive-text"
                data-confirm="Are you sure you want to revoke this API key?"
              >
                Revoke
              </.button>
            </div>
          <% end %>
        </li>
      </ul>

      <.modal id="add-api-key">
        <div>
          <div class="mb-6 text-center">
            <h3 class="text-base font-semibold text-gray-900">
              Create a new API key
            </h3>
            <div class="mt-2">
              <p class="text-sm text-gray-500">
                API keys allow you to manage settings through terraform and official GitHub Actions.
              </p>
            </div>
          </div>
        </div>
        <.form
          :let={f}
          for={@api_key_form}
          phx-change="validate_api_key"
          phx-submit={JS.push("add_api_key") |> hide_modal("add-api-key")}
          data-testid="add_api_key"
          class="focus-on-show"
        >
          <.input label="Name" field={f[:name]} />

          <h3 class="text-alpha-64 border-alpha-8 mt-6 mb-3 border-b pb-2 text-xs uppercase">
            Permissions
          </h3>
          <div class="flex flex-col gap-y-2">
            <.input type="checkbox" label="Full access" field={f[:full_access]} />
            <p class="text-alpha-64 mb-3 text-xs">
              Full access to all API endpoints.
            </p>
            <.input
              type="checkbox"
              label="Coverbot"
              field={f[:coverbot]}
              disabled={f[:full_access].value}
            />
            <p class="text-alpha-64 mb-3 text-xs">
              Allows posting code coverage and junit reports to Coverbot.
            </p>
            <.input
              type="checkbox"
              label="Querydesk limited"
              field={f[:querydesk_limited]}
              disabled={f[:full_access].value}
            />
            <p class="text-alpha-64 mb-3 text-xs">
              Allows managing ephemeral databases that were created with a limited API key, for example through GitHub Actions.
              To manage databases through Terraform, you need to use a full access API key.
            </p>
            <.input
              type="checkbox"
              label="Trigger workflows"
              field={f[:trigger_workflows]}
              disabled={f[:full_access].value}
            />
            <p class="text-alpha-64 mb-3 text-xs">
              Allows triggering workflows through the API.
            </p>
          </div>

          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#add-api-key")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit" variant="primary">Save</.button>
          </div>
        </.form>
      </.modal>

      <.modal :if={@editing_api_key} id={"edit-api-key-#{@editing_api_key.id}"} show={true}>
        <div>
          <div class="mb-6 text-center">
            <h3 class="text-base font-semibold text-gray-900">
              Edit API key
            </h3>
            <div class="mt-2">
              <p class="text-sm text-gray-500">
                API keys allow you to manage settings through terraform and official GitHub Actions.
              </p>
            </div>
          </div>
        </div>
        <.form
          :let={f}
          for={@api_key_form}
          phx-change="validate_api_key"
          phx-submit={JS.push("update_api_key") |> hide_modal("edit-api-key")}
          data-testid="update_api_key"
          class="focus-on-show"
        >
          <.input label="Name" field={f[:name]} id="edit-name" />

          <h3 class="text-alpha-64 border-alpha-8 mt-6 mb-3 border-b pb-2 text-xs uppercase">
            Permissions
          </h3>
          <div class="flex flex-col gap-y-2">
            <.input type="checkbox" label="Full access" field={f[:full_access]} id="edit-full-access" />
            <p class="text-alpha-64 mb-3 text-xs">
              Full access to all API endpoints.
            </p>
            <.input
              type="checkbox"
              label="Coverbot"
              id="edit-coverbot"
              field={f[:coverbot]}
              disabled={f[:full_access].value}
            />
            <p class="text-alpha-64 mb-3 text-xs">
              Allows posting code coverage and junit reports to Coverbot.
            </p>
            <.input
              type="checkbox"
              label="Querydesk limited"
              id="edit-querydesk-limited"
              field={f[:querydesk_limited]}
              disabled={f[:full_access].value}
            />
            <p class="text-alpha-64 mb-3 text-xs">
              Allows managing ephemeral databases that were created with a limited API key, for example through GitHub Actions.
              To manage databases through Terraform, you need to use a full access API key.
            </p>
            <.input
              type="checkbox"
              label="Trigger workflows"
              id="edit-trigger-workflows"
              field={f[:trigger_workflows]}
              disabled={f[:full_access].value}
            />
            <p class="text-alpha-64 mb-3 text-xs">
              Allows triggering workflows through the API.
            </p>
          </div>

          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={hide_modal("edit-api-key-#{@editing_api_key.id}")}
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

  def handle_event("validate_api_key", params, socket) do
    form =
      to_form(%{
        "name" => params["name"],
        "full_access" => params["full_access"] == "true",
        "coverbot" => params["coverbot"] == "true" or params["full_access"] == "true",
        "querydesk_limited" => params["querydesk_limited"] == "true" or params["full_access"] == "true",
        "trigger_workflows" => params["trigger_workflows"] == "true" or params["full_access"] == "true"
      })

    socket |> assign(api_key_form: form) |> noreply()
  end

  def handle_event("add_api_key", %{"name" => name} = params, socket) do
    permissions =
      params
      |> Map.take(["full_access", "coverbot", "querydesk_limited", "trigger_workflows"])
      |> Enum.filter(fn {_key, value} -> value == "true" end)
      |> Enum.map(fn {key, _value} -> key end)

    {:ok, api_key, token} = ApiKeys.create(socket.assigns.organization, name, permissions)

    api_keys = [Map.put(api_key, :token, token) | socket.assigns.api_keys]

    {:noreply, assign(socket, api_keys: api_keys, api_key_form: to_form(%{}))}
  end

  def handle_event("edit_api_key", %{"id" => id}, socket) do
    api_key = Enum.find(socket.assigns.api_keys, &(&1.id == id))
    full_access = Enum.member?(api_key.permissions, :full_access)

    form = %{
      "name" => api_key.name,
      "full_access" => full_access,
      "coverbot" => full_access or Enum.member?(api_key.permissions, :coverbot),
      "querydesk_limited" => full_access or Enum.member?(api_key.permissions, :querydesk_limited),
      "trigger_workflows" => full_access or Enum.member?(api_key.permissions, :trigger_workflows)
    }

    socket |> assign(editing_api_key: api_key, api_key_form: to_form(form)) |> noreply()
  end

  def handle_event("update_api_key", %{"name" => name} = params, socket) do
    permissions =
      params
      |> Map.take(["full_access", "coverbot", "querydesk_limited", "trigger_workflows"])
      |> Enum.filter(fn {_key, value} -> value == "true" end)
      |> Enum.map(fn {key, _value} -> key end)

    {:ok, api_key} = ApiKeys.update(socket.assigns.editing_api_key, name, permissions)

    api_keys = Utils.update_in(socket.assigns.api_keys, api_key)

    socket |> assign(api_keys: api_keys, editing_api_key: nil, api_key_form: to_form(%{})) |> noreply()
  end

  def handle_event("revoke_api_key", %{"id" => id}, socket) do
    index = Enum.find_index(socket.assigns.api_keys, &(&1.id == id))
    {api_key, api_keys} = List.pop_at(socket.assigns.api_keys, index)

    {:ok, _api_key} = ApiKeys.revoke(api_key)

    {:noreply, assign(socket, api_keys: api_keys)}
  end
end
