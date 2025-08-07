defmodule DevhubWeb.Live.Uptime.ServiceSettings do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Uptime
  alias Devhub.Uptime.Schemas.Service

  def mount(params, _session, socket) do
    {service, breadcrumbs} =
      with %{"id" => id} <- params,
           {:ok, service} <- Uptime.get_service(id: id, organization_id: socket.assigns.organization.id) do
        {service, [%{title: service.name, path: ~p"/uptime/services/#{service.id}"}, %{title: "Settings"}]}
      else
        _not_found ->
          {%Service{}, [%{title: "New Service"}]}
      end

    socket
    |> assign(
      page_title: "Devhub",
      service: service,
      changeset: Service.changeset(service, %{}),
      params: %{},
      breadcrumbs: [%{title: "Uptime", path: ~p"/uptime"} | breadcrumbs]
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title={@service.name} subtitle={@service.url}>
        <:actions>
          <.link_button
            navigate={if @service.id, do: ~p"/uptime/services/#{@service.id}", else: ~p"/uptime"}
            variant="secondary"
          >
            Cancel
          </.link_button>
          <.button phx-click="save">
            Save
          </.button>
        </:actions>
      </.page_header>

      <.form :let={f} for={@changeset} phx-change="update_changeset">
        <div class="flex flex-col gap-y-4">
          <div class="bg-surface-1 grid grid-cols-1 gap-x-4 gap-y-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Service Configuration</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                Basic configuration for how to perform requests.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-4">
              <.input field={f[:name]} label="service name" />
              <.input
                field={f[:method]}
                label="request method"
                type="select"
                options={[
                  {"GET", "GET"},
                  {"POST", "POST"},
                  {"PUT", "PUT"},
                  {"PATCH", "PATCH"},
                  {"DELETE", "DELETE"}
                ]}
              />
              <.input field={f[:url]} label="service url" />
              <.input field={f[:request_body]} type="textarea" label="request body" />
              <.input
                field={f[:interval_ms]}
                label="interval (ms)"
                tooltip="How often to check this service."
              />
              <.input
                field={f[:timeout_ms]}
                label="timeout (ms)"
                tooltip="How long the service has to respond before the check is considered a failure."
              />
            </div>
          </div>

          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 pt-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Request headers</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                Configure headers to send on each request.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-2">
              <.inputs_for :let={header} field={f[:request_headers]}>
                <input type="hidden" name="service[header_sort][]" value={header.index} />
                <div class="-mt-2 mb-1 flex items-center gap-x-2">
                  <div class="flex-1">
                    <.input field={header[:key]} placeholder="key" autocomplete="off" />
                  </div>

                  <div class="flex-1">
                    <.input field={header[:value]} placeholder="value" autocomplete="off" />
                  </div>

                  <label class="col-span-1 flex items-center align-text-bottom">
                    <input
                      type="checkbox"
                      name="service[header_drop][]"
                      value={header.index}
                      class="hidden"
                    />
                    <div class="bg-alpha-4 size-6 mt-2 flex items-center justify-center rounded-md">
                      <.icon name="hero-x-mark-mini" class="size-5 align-bottom text-gray-900" />
                    </div>
                  </label>
                </div>
              </.inputs_for>

              <label class="flex h-8 w-fit cursor-pointer items-center whitespace-nowrap rounded-md p-2 text-sm font-bold text-blue-800 ring-1 ring-inset ring-blue-300 transition-colors disabled:pointer-events-none disabled:opacity-50">
                <input type="checkbox" name="service[header_sort][]" class="hidden" />
                <div class="flex items-center gap-x-2">
                  <.icon name="hero-plus-mini" class="size-5" /> Add header
                </div>
              </label>
            </div>
          </div>

          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 pt-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Conditions</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                Configuration that determines if a check is marked as successful.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-4">
              <.input field={f[:expected_status_code]} label="expected status code" />
              <.input field={f[:expected_response_body]} label="expected response body" />
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("update_changeset", %{"service" => params}, socket) do
    changeset = socket.assigns.service |> Service.changeset(params) |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset, params: params)}
  end

  def handle_event("save", _params, socket) do
    if socket.assigns.permissions.super_admin do
      params = Map.put(socket.assigns.params, "organization_id", socket.assigns.organization.id)

      case Uptime.insert_or_update_service(socket.assigns.service, params) do
        {:ok, service} ->
          changeset = Service.changeset(service, %{})

          socket
          |> put_flash(:info, "Settings saved.")
          |> push_navigate(to: ~p"/uptime/services/#{service.id}/settings")
          |> assign(service: service, changeset: changeset)
          |> noreply()

        {:error, changeset} ->
          socket |> assign(changeset: changeset) |> noreply()
      end
    else
      {:noreply, socket}
    end
  end
end
