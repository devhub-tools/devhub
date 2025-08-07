defmodule DevhubWeb.CoverageControllerTest do
  use DevhubWeb.ConnCase, async: true

  describe "POST /api/v1/coverbot/coverage" do
    @tag :unauthenticated
    test "success", %{conn: conn} do
      organization = insert(:organization)
      api_key = build(:api_key, organization: organization)

      expect(Devhub.ApiKeys, :verify, fn "dh_123" -> {:ok, api_key} end)

      payload = %{
        "covered" => 10,
        "relevant" => 100,
        "percentage" => 10,
        "owner" => "coverbot-io",
        "repo" => "coverbot",
        "default_branch" => "main",
        "context" => %{"ref" => "refs/heads/main", "sha" => "1234567"}
      }

      assert %{
               "id" => "cov_" <> _id,
               "sha" => "1234567",
               "message" => "Coverage unchanged - 10 lines covered out of 100 (10%)",
               "state" => "success"
             } =
               conn
               |> put_req_header("x-api-key", "dh_123")
               |> post("/api/v1/coverbot/coverage", payload)
               |> json_response(200)

      # pull request increases coverage
      expect(Devhub.ApiKeys, :verify, fn "dh_123" -> {:ok, api_key} end)

      payload = %{
        "covered" => 11,
        "relevant" => 100,
        "percentage" => 11,
        "owner" => "coverbot-io",
        "repo" => "coverbot",
        "default_branch" => "main",
        "context" => %{
          "ref" => "refs/pulls/1",
          "payload" => %{
            "pull_request" => %{"head" => %{"sha" => "2345678"}}
          }
        }
      }

      assert %{
               "id" => "cov_" <> _id,
               "sha" => "2345678",
               "message" => "Coverage increased 1% - 11 lines covered out of 100 (11%)",
               "state" => "success"
             } =
               conn
               |> put_req_header("x-api-key", "dh_123")
               |> post("/api/v1/coverbot/coverage", payload)
               |> json_response(200)
    end

    test "No api key", %{conn: conn} do
      payload = %{
        "covered" => 10,
        "relevant" => 100,
        "percentage" => 10,
        "owner" => "coverbot-io",
        "repo" => "coverbot",
        "default_branch" => "main",
        "context" => %{"ref" => "refs/heads/main", "sha" => "1234567"}
      }

      assert conn
             |> post("/api/v1/coverbot/coverage", payload)
             |> response(401)
    end
  end
end
