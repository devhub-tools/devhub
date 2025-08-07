defmodule DevhubWeb.Live.Uptime.Dashboard do
  @moduledoc """
  Dashboard page shows a summary of all services.
  """
  use DevhubWeb, :live_view

  alias Devhub.Uptime
  alias Devhub.Uptime.Schemas.Check
  alias Devhub.Uptime.Schemas.Service
  alias Phoenix.LiveView.AsyncResult

  # Placeholder for dashboard setting
  @show_checks_since DateTime.add(DateTime.utc_now(), -24, :hour)
  @show_checks_until DateTime.utc_now()

  def mount(_params, _session, socket) do
    socket =
      assign(
        socket,
        show_checks_since: @show_checks_since,
        show_checks_until: @show_checks_until,
        changeset: Service.changeset(%{}),
        services: AsyncResult.loading(),
        check_limit: 50
      )

    if connected?(socket) do
      Uptime.subscribe_checks()
    end

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      socket |> assign(view: params["view"] || "day") |> noreply()
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title="Uptime monitoring">
        <:actions>
          <.link_button :if={@permissions.super_admin} navigate={~p"/uptime/services/new"}>
            New Service
          </.link_button>
        </:actions>
      </.page_header>
      <div id="window-resize" phx-hook="WindowResize" class="divide-alpha-16 relative divide-y">
        <.async_result :let={services} assign={@services}>
          <:loading>
            <div class="flex items-center justify-center">
              <div class="size-10 mt-12">
                <.spinner />
              </div>
            </div>
          </:loading>
          <div :if={Enum.empty?(services)} class="flex flex-col gap-y-4">
            <div
              :for={_i <- 1..4}
              :if={Enum.empty?(services)}
              class="bg-surface-1 blur-xs flex w-full items-center gap-x-2 rounded-lg p-4"
            >
              <div class="w-full">
                <div class="mb-2 flex flex-row items-center justify-between">
                  <div class="flex flex-col gap-y-1">
                    <h2 class="mr-2 text-sm font-bold">
                      Devhub
                    </h2>
                    <p class="text-xs text-gray-600">
                      https://devhub.tools
                    </p>
                  </div>
                  <time class="block text-sm text-gray-700">
                    100ms
                  </time>
                </div>
                <.service_checks_summary
                  checks={
                    Enum.map(0..@check_limit, fn _ ->
                      %Check{status: :success, inserted_at: DateTime.utc_now()}
                    end)
                  }
                  window_started_at={@show_checks_since}
                  window_ended_at={@show_checks_until}
                  total={@check_limit}
                />
              </div>
              <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                <.icon name="hero-chevron-right-mini" />
              </div>
            </div>
            <div class="bg-surface-2 absolute top-36 left-1/2 w-96 -translate-x-1/2 rounded">
              <div class="p-6 text-center">
                <.icon name="hero-clock" class="size-12 mx-auto text-gray-400" />
                <h3 class="mt-2 text-sm font-semibold text-gray-900">No uptime checks</h3>
                <p :if={@permissions.super_admin} class="mt-1 text-sm text-gray-500">
                  Get started by adding a new service.
                </p>
                <div class="mt-6">
                  <.link_button :if={@permissions.super_admin} navigate={~p"/uptime/services/new"}>
                    New Service
                  </.link_button>
                </div>
              </div>
            </div>
          </div>

          <div :if={not Enum.empty?(services)} class="flex flex-col gap-y-4">
            <.link
              :for={service <- services}
              navigate={~p"/uptime/services/#{service.id}"}
              class="bg-surface-1 flex w-full items-center gap-x-2 rounded-lg p-4 hover:bg-alpha-4"
            >
              <div class="w-full">
                <div class="mb-2 flex flex-row items-center justify-between">
                  <div class="flex flex-col gap-y-1">
                    <h2 class="mr-2 text-sm font-bold">
                      {service.name}
                    </h2>
                    <p class="text-xs text-gray-600">
                      {service.url}
                    </p>
                  </div>
                  <time :if={not Enum.empty?(service.checks)} class="block text-sm text-gray-700">
                    {hd(service.checks) |> Map.get(:request_time)}ms
                  </time>
                </div>
                <.service_checks_summary
                  checks={service.checks}
                  window_started_at={@show_checks_since}
                  window_ended_at={@show_checks_until}
                  total={length(service.checks)}
                />
              </div>
              <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                <.icon name="hero-chevron-right-mini" />
              </div>
            </.link>
          </div>
        </.async_result>
      </div>
    </div>
    """
  end

  def handle_event("window_resize", values, socket) do
    check_limit = values |> Map.get("width", 800) |> calculate_checks_limit()

    socket
    |> assign(:check_limit, check_limit)
    |> fetch_data()
    |> noreply()
  end

  def handle_info({Check, %Check{} = check}, %{assigns: %{services: %{ok?: true}}} = socket) do
    service_id = check.service_id

    case Enum.find(socket.assigns.services.result, fn service -> service.id == service_id end) do
      nil ->
        {:noreply, socket}

      service ->
        checks =
          if length(service.checks) >= socket.assigns.check_limit do
            # Keep the checks list fixed to calculated amount due to screen width constraints
            List.delete_at(service.checks, -1)
          else
            service.checks
          end

        checks = [check | checks]
        updated_service = %{service | checks: checks}

        updated_services =
          Enum.map(socket.assigns.services.result, fn s -> if s.id == service_id, do: updated_service, else: s end)

        {:noreply, assign(socket, services: AsyncResult.ok(socket.assigns.services, updated_services))}
    end
  end

  def handle_info({Check, _check}, socket) do
    {:noreply, socket}
  end

  def handle_async(:data, {:ok, data}, socket) do
    socket
    |> assign(services: AsyncResult.ok(socket.assigns.services, data.services))
    |> noreply()
  end

  defp fetch_data(socket) do
    %{
      organization: organization,
      check_limit: check_limit
    } = socket.assigns

    start_async(socket, :data, fn ->
      services =
        Uptime.list_services(organization.id, preload_checks: true, limit_checks: check_limit)

      %{
        services: services
      }
    end)
  end
end
