defmodule DevhubWeb.Components.Uptime.ServiceChecksSummary do
  @moduledoc false
  use DevhubWeb, :html

  @doc """
  Render the service checks for a given window.
  """
  attr :checks, :list, required: true
  attr :total, :integer, required: true
  attr :window_started_at, :map, default: nil
  attr :window_ended_at, :map, default: nil

  def service_checks_summary(assigns) do
    since =
      case Enum.reverse(assigns.checks) do
        [%{inserted_at: inserted_at} | _rest] -> inserted_at
        _checks -> nil
      end

    {until, time} =
      case assigns.checks do
        [%{inserted_at: inserted_at, request_time: time} | _rest] -> {inserted_at, time}
        _checks -> {nil, nil}
      end

    assigns =
      assigns
      |> assign(:time, time)
      |> assign(:since, since)
      |> assign(:until, until)
      |> assign(:checks, Enum.reverse(assigns.checks))

    ~H"""
    <div class="space-y-1">
      <div class="flex flex-row">
        <%= for check <- @checks do %>
          <.check_indicator check={check} total={@total} />
        <% end %>
      </div>
      <div class="flex flex-row justify-between text-xs text-gray-500">
        <format-date date={@since} format="relative"></format-date>
        <format-date date={@until} format="relative"></format-date>
      </div>
    </div>
    """
  end
end
