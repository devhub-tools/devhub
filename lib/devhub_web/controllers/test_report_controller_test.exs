defmodule DevhubWeb.V1.TestReportControllerTest do
  use DevhubWeb.ConnCase, async: true

  alias Devhub.Coverbot.TestReports.Schemas.TestSuite
  alias Devhub.Repo

  describe "POST /junit/:repo_owner/:repo/:sha" do
    @tag :unauthenticated
    test "success, test_suite already exists", %{conn: conn} do
      %{id: organization_id} = organization = insert(:organization)

      %{id: repo_id, name: repo_name, owner: repo_owner} =
        repository = insert(:repository, organization_id: organization_id)

      %{id: test_suite_id} =
        insert(:test_suite, name: "devhub_elixir", organization: organization, repository: repository)

      %{sha: sha} = insert(:commit, repository_id: repo_id, organization_id: organization_id)

      upload = %Plug.Upload{
        path: "test/support/junit/devhub-report_file_test.xml",
        filename: "devhub_elixir.xml"
      }

      expect(Devhub.ApiKeys, :verify, fn "dh_123" ->
        {:ok, build(:api_key, organization: organization)}
      end)

      assert conn
             |> put_req_header("x-api-key", "dh_123")
             |> post(~p"/api/v1/coverbot/junit/#{repo_owner}/#{repo_name}/#{sha}", %{"junit_xml" => upload})
             |> json_response(200)

      assert [%TestSuite{id: ^test_suite_id}] = Repo.all(TestSuite)
    end

    @tag :unauthenticated
    test "success, test_suite doesn't exist yet", %{conn: conn} do
      %{id: organization_id} = organization = insert(:organization)

      %{id: repo_id, name: repo_name, owner: repo_owner} =
        repository = insert(:repository, organization_id: organization_id)

      _test_suite_run =
        insert(:test_suite, name: "devhub_elixir", organization: organization, repository: repository)

      %{sha: sha} = insert(:commit, repository_id: repo_id, organization_id: organization_id)

      upload = %Plug.Upload{
        path: "test/support/junit/devhub-report_file_test.xml",
        # note that this is a different name than the already existing devhub_elixir
        filename: "devhub_playwright.xml"
      }

      expect(Devhub.ApiKeys, :verify, fn "dh_123" ->
        {:ok, build(:api_key, organization: organization)}
      end)

      assert conn
             |> put_req_header("x-api-key", "dh_123")
             |> post(~p"/api/v1/coverbot/junit/#{repo_owner}/#{repo_name}/#{sha}", %{"junit_xml" => upload})
             |> json_response(200)

      assert TestSuite |> Repo.all() |> length() == 2
    end

    @tag :unauthenticated
    test "error parsing junit file", %{conn: conn} do
      %{id: organization_id} = organization = insert(:organization)
      %{id: repo_id, name: repo_name, owner: repo_owner} = insert(:repository, organization_id: organization_id)
      %{sha: sha} = insert(:commit, repository_id: repo_id, organization_id: organization_id)

      upload = %Plug.Upload{
        path: "test/support/junit/malformed_junit_test_file.xml",
        filename: "malformed_junit_test_file.xml"
      }

      expect(Devhub.ApiKeys, :verify, fn "dh_123" ->
        {:ok, build(:api_key, organization: organization)}
      end)

      resp =
        conn
        |> put_req_header("x-api-key", "dh_123")
        |> post(~p"/api/v1/coverbot/junit/#{repo_owner}/#{repo_name}/#{sha}", %{"junit_xml" => upload})
        |> json_response(400)

      assert %{
               "error" => "error parsing junit file"
             } = resp
    end

    @tag :unauthenticated
    test "repository not found", %{conn: conn} do
      organization = insert(:organization)
      repo_owner = "unknown"
      repo_name = "unknown"
      sha = "sha"

      upload = %Plug.Upload{
        path: "test/support/junit/devhub-report_file_test.xml",
        filename: "devhub-report_file_test.xml"
      }

      expect(Devhub.ApiKeys, :verify, fn "dh_123" ->
        {:ok, build(:api_key, organization: organization)}
      end)

      resp =
        conn
        |> put_req_header("x-api-key", "dh_123")
        |> post(~p"/api/v1/coverbot/junit/#{repo_owner}/#{repo_name}/#{sha}", %{"junit_xml" => upload})
        |> json_response(404)

      assert %{"error" => "{:error, :repository_not_found}"} = resp
    end
  end
end
