defmodule DevhubWeb.Plugs.VerifyApiKeyTest do
  use DevhubWeb.ConnCase, async: true

  alias Devhub.ApiKeys
  alias DevhubWeb.Plugs.VerifyApiKey

  test "blocks invalid api keys", %{conn: conn} do
    expect(ApiKeys, :verify, fn "invalid" -> {:error, :invalid_api_key} end)

    assert %{status: 401, state: :sent} =
             conn
             |> put_req_header("x-api-key", "invalid")
             |> VerifyApiKey.call([])
  end

  test "allows valid api keys", %{conn: conn} do
    api_key = build(:api_key)

    expect(ApiKeys, :verify, fn "dh_123" -> {:ok, api_key} end)

    assert %{status: nil, state: :unset} =
             conn
             |> put_req_header("x-api-key", "dh_123")
             |> VerifyApiKey.call([])
  end

  test "allowed paths" do
    check_allowed_path("/api/v1/coverbot/coverage", [:coverbot])
    check_allowed_path("/api/v1/querydesk/databases/setup", [:querydesk_limited])
    check_allowed_path("/api/v1/querydesk/databases/remove/pr-1", [:querydesk_limited])
    check_allowed_path("/api/v1/workflows/123/run", [:trigger_workflows])
    check_allowed_path("/api/v1/dashboards/123", [:full_access])
  end

  defp check_allowed_path(path, permissions) do
    # allowed with correct permissions
    expect(ApiKeys, :verify, fn "dh_123" -> {:ok, build(:api_key, permissions: permissions)} end)

    assert %{status: nil, state: :unset} =
             :get
             |> build_conn(path, nil)
             |> put_req_header("x-api-key", "dh_123")
             |> VerifyApiKey.call([])

    # not allowed without correct permissions
    expect(ApiKeys, :verify, fn "dh_123" -> {:ok, build(:api_key, permissions: [])} end)

    assert %{status: 401, state: :sent} =
             :get
             |> build_conn(path, nil)
             |> put_req_header("x-api-key", "dh_123")
             |> VerifyApiKey.call([])
  end
end
