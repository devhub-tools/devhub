defmodule DevhubWeb.BadgeControllerTest do
  use DevhubWeb.ConnCase, async: true

  alias Devhub.Integrations.GitHub

  test "GET /api/v1/coverbot/:owner/:repo/:branch/badge.json", %{conn: conn} do
    %{owner: owner, name: name} = repository = build(:repository)
    coverage = build(:coverage, repository: repository)

    expect(GitHub, :get_repository, fn [owner: ^owner, name: ^name] -> {:ok, repository} end)
    expect(Devhub.Coverbot, :coverage_percentage, fn ^repository, "main" -> {:ok, coverage.percentage} end)

    assert %{
             "color" => "#c81e1e",
             "label" => "coverbot",
             "message" => "10%",
             "schemaVersion" => 1
           } =
             conn
             |> get("/api/v1/coverbot/#{repository.owner}/#{repository.name}/main/badge.json")
             |> json_response(200)
  end

  test "GET /api/v1/uptime/uptime/:duration/badge.json", %{conn: conn} do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)
    insert(:uptime_check_summary, service: service, date: Date.utc_today(), avg_request_time: 100)

    assert %{
             "color" => "#057a55",
             "label" => "uptime 7d",
             "message" => "100%",
             "schemaVersion" => 1
           } =
             conn
             |> get("/api/v1/uptime/#{service.id}/uptime/7d/badge.json")
             |> json_response(200)
  end

  test "GET /api/v1/uptime/latency/:duration/badge.json", %{conn: conn} do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)
    insert(:uptime_check_summary, service: service, date: Date.utc_today(), avg_request_time: 100)

    assert %{
             "color" => "#057a55",
             "label" => "response time 7d",
             "message" => "100ms",
             "schemaVersion" => 1
           } =
             conn
             |> get("/api/v1/uptime/#{service.id}/latency/7d/badge.json")
             |> json_response(200)
  end

  test "GET /api/v1/uptime/health/badge.json", %{conn: conn} do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)
    insert(:uptime_check, organization: organization, service: service, status: :success)

    assert %{
             "color" => "#057a55",
             "label" => "health",
             "message" => "up",
             "schemaVersion" => 1
           } =
             conn
             |> get("/api/v1/uptime/#{service.id}/health/badge.json")
             |> json_response(200)
  end
end
