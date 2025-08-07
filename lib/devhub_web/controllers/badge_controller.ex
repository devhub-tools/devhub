defmodule DevhubWeb.V1.BadgeController do
  use DevhubWeb, :controller

  alias Devhub.Coverbot
  alias Devhub.Integrations.GitHub
  alias Devhub.Uptime
  alias DevhubWeb.Components.ShieldBadge

  @logo File.read!("priv/static/images/logo.svg")

  def coverage(conn, params) do
    with {:ok, repository} <- GitHub.get_repository(owner: params["owner"], name: params["repo"]),
         {:ok, percentage} <- Coverbot.coverage_percentage(repository, params["branch"]) do
      percentage = percentage |> Decimal.round(0) |> Decimal.to_integer()
      value = "#{percentage}%"
      color = ShieldBadge.coverage_color(percentage)

      json(conn, %{schemaVersion: 1, label: "coverbot", message: value, color: color, logoSvg: @logo})
    else
      _error ->
        conn
        |> put_status(404)
        |> text("not found")
    end
  end

  def uptime(conn, %{"id" => id, "duration" => duration}) do
    percentage = Uptime.uptime_percentage(id, duration)

    value =
      percentage
      |> Decimal.from_float()
      |> Decimal.mult(100)
      |> Decimal.round(0)
      |> Decimal.to_string()
      |> Kernel.<>("%")

    color = ShieldBadge.uptime_color(percentage)

    json(conn, %{schemaVersion: 1, label: "uptime #{duration}", message: value, color: color, logoSvg: @logo})
  end

  def response_time(conn, %{"id" => id, "duration" => duration}) do
    latency = Uptime.latency(id, duration)
    value = Integer.to_string(latency) <> "ms"
    color = ShieldBadge.response_time_color(latency)

    json(conn, %{schemaVersion: 1, label: "response time #{duration}", message: value, color: color, logoSvg: @logo})
  end

  def health(conn, %{"id" => id}) do
    {:ok, service} = Uptime.get_service([id: id], preload_checks: true, limit_checks: 1)
    up? = hd(service.checks).status == :success
    value = (up? && "up") || "down"
    color = ShieldBadge.health_color(up?)

    json(conn, %{schemaVersion: 1, label: "health", message: value, color: color, logoSvg: @logo})
  end
end
