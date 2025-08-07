defmodule DevhubWeb.V1.TestReportController do
  use DevhubWeb, :controller

  alias Devhub.Coverbot
  alias Devhub.Integrations.GitHub

  def junit(conn, %{"sha" => sha, "junit_xml" => %Plug.Upload{filename: filename, path: filepath}} = params) do
    filename = Path.rootname(filename)

    with {:ok, repository} <- GitHub.get_repository(owner: params["repo_owner"], name: params["repo"]),
         commit =
           GitHub.import_commit(%{organization_id: repository.organization_id, sha: sha, repository_id: repository.id}),
         {:ok, test_run} <-
           Coverbot.upsert_test_suite(%{
             name: filename,
             organization_id: repository.organization_id,
             repository_id: repository.id
           }),
         {:ok, junit_xml_file} <- File.read(filepath),
         {:ok, _test_suite_run} <- Coverbot.parse_junit_file(test_run, junit_xml_file, commit) do
      json(conn, 200)
    else
      {:error, :error_parsing_junit_file} ->
        conn
        |> put_status(400)
        |> json(%{error: "error parsing junit file"})

      error ->
        conn
        |> put_status(404)
        |> json(%{error: inspect(error)})
    end
  end
end
