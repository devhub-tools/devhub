defmodule DevhubWeb.Components.Uptime.TestNowButton do
  @moduledoc false
  use DevhubWeb, :live_component

  alias Devhub.Uptime

  def mount(socket) do
    {:ok, assign(socket, service_check: %{})}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-x-2" id={@id}>
      <div :if={@service_check[:success]} class="tooltip tooltip-left text-green-500">
        <.icon name="hero-check-circle" class="size-5" />
        <span class="tooltiptext text-nowrap">
          Connection successful: status code {@service_check.status_code}
        </span>
      </div>
      <div :if={@service_check[:success] == false} class="tooltip tooltip-left text-red-500">
        <.icon name="hero-exclamation-circle" class="size-5" />
        <span class="tooltiptext text-nowrap">
          Error connecting: {@service_check.error_message}
        </span>
      </div>
      <.button
        type="button"
        phx-click="check_service"
        phx-target={@myself}
        variant="text"
        data-testid="check-service-button"
      >
        Test Now
      </.button>
    </div>
    """
  end

  def handle_event("check_service", _params, %{assigns: %{service: service}} = socket) do
    case Uptime.check_service(service) do
      {:ok, %{status_code: status_code}} ->
        socket
        |> assign(service_check: %{success: true, status_code: status_code})
        |> noreply()

      {:error, %{status_code: status_code}} ->
        socket
        |> assign(service_check: %{success: false, error_message: "unexpected status code #{status_code}"})
        |> noreply()

      {:error, error} ->
        socket
        |> assign(service_check: %{success: false, error_message: inspect(error)})
        |> noreply()
    end
  end
end
