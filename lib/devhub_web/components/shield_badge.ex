defmodule DevhubWeb.Components.ShieldBadge do
  @moduledoc """
  Components for rendering badges in controllers _and_ live views.

  This module is used by both the `DevhubWeb.BadgeController` and the
  `DevhubWeb.ServiceLive` live view to render SVG badges for uptimes and
  response times. So it has to handle assigns from both Plug.Conn as wells as
  Phoenix.Component.
  """

  use DevhubWeb, :html

  @badge_colors %{
    excellent: "#057a55",
    great: "#31c48d",
    good: "#bcf0da",
    okay: "#fdf6b2",
    bad: "#f05252",
    very_bad: "#c81e1e"
  }

  @logo "priv/static/images/logo.svg" |> File.read!() |> Base.encode64()

  @doc """
  Utilizes shields.io to render a badge.
  """
  def shield_badge(assigns) do
    assigns = default_assigns(assigns, assigns.type)
    id = to_string(assigns.type)
    color = String.replace(assigns.color, "#", "")

    assigns = assign(assigns, logo: @logo, id: id, color: color)

    ~H"""
    <img
      alt={"#{@id} badge"}
      src={"https://img.shields.io/badge/#{@label}-#{URI.encode(@value)}-#{@color}?logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2C#{@logo}"}
    />
    """
  end

  defp default_assigns(assigns, :coverage) do
    percentage = assigns[:percentage] |> Decimal.round(0) |> Decimal.to_integer()
    value = "#{percentage}%"

    assign(assigns,
      color: coverage_color(percentage),
      label: "coverbot",
      value: value
    )
  end

  defp default_assigns(assigns, :uptime) do
    value =
      assigns[:uptime]
      |> Decimal.from_float()
      |> Decimal.mult(100)
      |> Decimal.round(0)
      |> Decimal.to_string()
      |> Kernel.<>("%")

    assign(assigns,
      value: value,
      color: uptime_color(assigns[:uptime]),
      label: "uptime #{assigns[:duration]}"
    )
  end

  defp default_assigns(assigns, :latency) do
    value = Integer.to_string(assigns[:average_response_time]) <> "ms"

    assign(assigns,
      value: value,
      color: response_time_color(assigns[:average_response_time]),
      label: "response time #{assigns[:duration]}"
    )
  end

  defp default_assigns(assigns, :health) do
    assign(assigns,
      color: health_color(assigns[:up]),
      label: "health",
      value: (assigns[:up] && "up") || "down"
    )
  end

  def coverage_color(coverage) do
    cond do
      coverage >= 95 -> @badge_colors.excellent
      coverage >= 90 -> @badge_colors.great
      coverage >= 80 -> @badge_colors.good
      coverage >= 70 -> @badge_colors.okay
      coverage >= 60 -> @badge_colors.bad
      true -> @badge_colors.very_bad
    end
  end

  def uptime_color(uptime) do
    cond do
      uptime >= 0.975 -> @badge_colors.excellent
      uptime >= 0.95 -> @badge_colors.great
      uptime >= 0.9 -> @badge_colors.good
      uptime >= 0.8 -> @badge_colors.okay
      uptime >= 0.65 -> @badge_colors.bad
      true -> @badge_colors.very_bad
    end
  end

  def response_time_color(time) do
    cond do
      time <= 300 -> @badge_colors.excellent
      time <= 500 -> @badge_colors.great
      time <= 1000 -> @badge_colors.good
      time <= 2000 -> @badge_colors.okay
      time <= 3000 -> @badge_colors.bad
      true -> @badge_colors.very_bad
    end
  end

  def health_color(success) do
    (success && @badge_colors.excellent) || @badge_colors.very_bad
  end
end
