defmodule Devhub.TerraDesk.Actions.HandleWebhook do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub.Client
  alias Devhub.Integrations.Schemas.GitHubApp
  alias Devhub.Repo
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan
  alias Devhub.TerraDesk.Schemas.Workspace

  @callback handle_webhook(GitHubApp.t(), map()) :: :ok
  # for pushes we only trigger plans for the default branch and if there are relevant changes
  def handle_webhook(app, %{"ref" => "refs/heads/" <> branch} = event) do
    owner = event["repository"]["owner"]["name"]
    repo = event["repository"]["name"]
    sha = event["after"]

    changed_files = Enum.flat_map(event["commits"], &(&1["added"] ++ &1["modified"] ++ &1["removed"]))

    app.organization_id
    |> get_workspaces(owner, repo, branch)
    |> Enum.each(fn workspace ->
      has_changes? = is_nil(workspace.path) or Enum.any?(changed_files, &String.starts_with?(&1, workspace.path))

      if has_changes? do
        TerraDesk.create_plan(workspace, branch, commit_sha: sha, run: true)
      end
    end)
  end

  def handle_webhook(app, %{"action" => "closed", "pull_request" => pull_request}) do
    query =
      from p in Plan,
        join: w in assoc(p, :workspace),
        join: r in assoc(w, :repository),
        where: p.organization_id == ^app.organization_id,
        where: r.owner == ^pull_request["head"]["repo"]["owner"]["login"],
        where: r.name == ^pull_request["head"]["repo"]["name"],
        where: p.github_branch == ^pull_request["head"]["ref"],
        where: p.status in [:queued, :planned]

    Repo.update_all(
      query,
      set: [status: :canceled, output: nil]
    )

    :ok
  end

  def handle_webhook(app, %{"action" => action, "pull_request" => pull_request} = event)
      when action in ["opened", "synchronize"] do
    branch = pull_request["head"]["ref"]
    owner = pull_request["head"]["repo"]["owner"]["login"]
    repo = pull_request["head"]["repo"]["name"]
    head_sha = pull_request["head"]["sha"]

    with {:ok, integration} <- Integrations.get_by(organization_id: app.organization_id, provider: :github) do
      app.organization_id
      |> get_workspaces(owner, repo)
      |> Enum.each(fn workspace ->
        has_changes? = is_nil(workspace.path) or pr_changed_relevant_file?(integration, workspace, event)

        if has_changes? do
          with {:ok, plan} <- TerraDesk.create_plan(workspace, branch, commit_sha: head_sha) do
            Client.create_check(
              integration,
              workspace.repository,
              %{
                name: "TerraDesk: #{workspace.name}",
                head_sha: head_sha,
                details_url: DevhubWeb.Endpoint.url() <> "/terradesk/plans/#{plan.id}",
                external_id: plan.id,
                status: "queued"
              }
            )
          end
        else
          Client.create_check(
            integration,
            workspace.repository,
            %{
              name: "TerraDesk: #{workspace.name}",
              head_sha: head_sha,
              conclusion: "neutral"
            }
          )
        end
      end)
    end
  end

  def handle_webhook(_app, _event) do
    :ok
  end

  defp get_workspaces(organization_id, repo_owner, repo_name, branch) do
    query =
      from [_w, r] in core_query(organization_id, repo_owner, repo_name),
        where: r.default_branch == ^branch

    Repo.all(query)
  end

  defp get_workspaces(organization_id, repo_owner, repo_name) do
    query = core_query(organization_id, repo_owner, repo_name)

    Repo.all(query)
  end

  defp core_query(organization_id, repo_owner, repo_name) do
    from w in Workspace,
      join: r in assoc(w, :repository),
      where: r.owner == ^repo_owner,
      where: r.name == ^repo_name,
      where: w.organization_id == ^organization_id,
      preload: [:organization, repository: r]
  end

  defp pr_changed_relevant_file?(integration, workspace, event) do
    {:ok, %{body: %{"files" => files}}} =
      Client.compare(
        integration,
        event["repository"]["full_name"],
        event["pull_request"]["base"]["ref"],
        event["pull_request"]["head"]["ref"]
      )

    changed_files = Enum.map(files, & &1["filename"])

    Enum.any?(changed_files, &String.starts_with?(&1, workspace.path))
  end
end
