defmodule DevhubWeb.V1.CoverageController do
  use DevhubWeb, :controller

  alias Devhub.Coverbot
  alias Devhub.Coverbot.Cache
  alias Devhub.Integrations.GitHub

  def create(conn, params) do
    %{sha: sha} = coverage_info = parse_payload(params)

    {:ok, repository} =
      GitHub.upsert_repository(%{
        organization_id: conn.assigns.organization_id,
        owner: params["owner"],
        name: params["repo"],
        default_branch: params["default_branch"],
        pushed_at: DateTime.utc_now()
      })

    {:ok, coverage} =
      coverage_info
      |> Map.put(:organization_id, conn.assigns.organization_id)
      |> Map.put(:repository_id, repository.id)
      |> Coverbot.upsert_coverage()

    with "refs/pull/" <> rest <- coverage_info.ref do
      number = rest |> String.split("/") |> List.first()
      Cache.delete("pr_files:#{repository.id}:#{number}")
    end

    resp =
      case Coverbot.get_latest_coverage(repository, params["default_branch"]) do
        {:ok, latest_coverage} ->
          coverage_change = Decimal.sub(params["percentage"], latest_coverage.percentage)

          {message, state} =
            if Decimal.eq?(coverage_change, 0) do
              {"Coverage unchanged", "success"}
            else
              {message_verb, state} =
                if Decimal.positive?(coverage_change),
                  do: {"increased", "success"},
                  else: {"decreased", "failure"}

              {"Coverage #{message_verb} #{Decimal.abs(coverage_change)}%", state}
            end

          %{
            id: coverage.id,
            sha: sha,
            state: state,
            message:
              "#{message} - #{params["covered"]} lines covered out of #{params["relevant"]} (#{params["percentage"]}%)"
          }

        _result ->
          %{
            id: coverage.id,
            sha: sha,
            state: "success",
            message: "#{params["covered"]} lines covered out of #{params["relevant"]} (#{params["percentage"]}%)"
          }
      end

    json(conn, resp)
  end

  defp parse_payload(
         %{
           "covered" => covered,
           "relevant" => relevant,
           "percentage" => percentage,
           "owner" => owner,
           "repo" => repo,
           "default_branch" => default_branch,
           "context" => %{"ref" => ref}
         } = params
       ) do
    params
    |> parse_sha_from_payload()
    |> Map.merge(%{
      covered: covered,
      is_for_default_branch: ref == "refs/heads/#{default_branch}",
      owner: owner,
      percentage: percentage,
      ref: ref,
      relevant: relevant,
      repo: repo,
      files: params["files"]
    })
  end

  defp parse_sha_from_payload(%{"context" => %{"payload" => %{"pull_request" => %{"head" => %{"sha" => sha}}}}}) do
    %{sha: sha}
  end

  defp parse_sha_from_payload(%{"context" => %{"sha" => sha}}) do
    %{sha: sha}
  end
end
