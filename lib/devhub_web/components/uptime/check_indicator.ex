defmodule DevhubWeb.Components.Uptime.CheckIndicator do
  @moduledoc false
  use DevhubWeb, :html

  @doc """
  Render the check indicator box for a service check.

  This expects a total so it can set a fixed width, especially when service is new and checks are filling up container.
  """
  attr :check, :map, required: true
  attr :total, :integer, required: true

  def check_indicator(assigns) do
    bar_class =
      case assigns.check.status do
        :success -> "border-2 border-green-400 bg-green-400 group-hover/color-bar:border-alpha-64"
        :pending -> "border-2 border-yellow-400 bg-yellow-400 group-hover/color-bar:border-alpha-64"
        :failure -> "border-2 border-red-400 bg-red-400 group-hover/color-bar:border-alpha-64"
        _unknown -> "border-2 border-gray-400 bg-gray-400 group-hover/color-bar:border-alpha-64"
      end

    assigns =
      assigns
      |> assign(:bar_class, bar_class)
      |> assign(
        :width_percent,
        100 / assigns.total
      )

    ~H"""
    <.hover_card style={"max-width:#{@width_percent}%"} class="group/color-bar h-8 w-full px-px">
      <div class={Enum.join(["h-full w-full rounded-full", @bar_class], "  ")} />
      <:hover_content>
        <div class="space-y-2 text-sm">
          <div class="flex items-center">
            <span class="text-muted-foreground text-xs">
              <format-date date={@check.inserted_at} format="datetime"></format-date>
            </span>
          </div>
          <p>
            <span class="font-semibold">Status code</span>: {@check.status_code}
          </p>
          <%= if @check.dns_time do %>
            <p><span class="font-semibold">DNS time</span>: {@check.dns_time}ms</p>
          <% end %>
          <%= if @check.connect_time do %>
            <p><span class="font-semibold">Connect time</span>: {@check.connect_time}ms</p>
          <% end %>
          <%= if @check.tls_time do %>
            <p><span class="font-semibold">TLS time</span>: {@check.tls_time}ms</p>
          <% end %>
          <%= if @check.first_byte_time do %>
            <p>
              <span class="font-semibold">Time to first byte</span>: {@check.first_byte_time}ms
            </p>
          <% end %>
          <%= if @check.request_time do %>
            <p><span class="font-semibold">Total time</span>: {@check.request_time}ms</p>
          <% end %>
        </div>
      </:hover_content>
    </.hover_card>
    """
  end
end
