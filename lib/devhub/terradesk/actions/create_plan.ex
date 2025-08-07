defmodule Devhub.TerraDesk.Actions.CreatePlan do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.TerraDesk.Jobs.RunPlan
  alias Devhub.TerraDesk.Schemas.Plan
  alias Devhub.TerraDesk.Schemas.Workspace

  require Logger

  @callback create_plan(Workspace.t(), String.t(), Keyword.t()) ::
              {:ok, Plan.t()} | {:error, Ecto.Changeset.t()}
  def create_plan(workspace, github_branch, opts) do
    auto_run = Keyword.get(opts, :run, false) or workspace.run_plans_automatically

    Repo.transaction(fn ->
      with :ok <- cancel_plans(workspace, github_branch),
           {:ok, plan} <- do_create_plan(workspace, github_branch, opts),
           {:ok, _job} <- maybe_insert_job(plan, auto_run) do
        plan
      else
        {:error, error} ->
          Logger.error("Failed to create plan: #{inspect(error)}")
          Devhub.Repo.rollback(error)
      end
    end)
  end

  defp do_create_plan(workspace, github_branch, opts) do
    %{
      workspace: workspace,
      github_branch: github_branch,
      commit_sha: opts[:commit_sha],
      user: opts[:user],
      organization: workspace.organization,
      targeted_resources: opts[:targeted_resources] || [],
      schedule_id: opts[:schedule_id]
    }
    |> Plan.create_changeset()
    |> Repo.insert()
  end

  defp cancel_plans(workspace, github_branch) do
    Repo.update_all(
      from(p in Plan,
        where: p.workspace_id == ^workspace.id and p.status in [:queued, :planned] and p.github_branch == ^github_branch
      ),
      set: [status: :canceled, output: nil]
    )

    :ok
  end

  defp maybe_insert_job(plan, true) do
    %{id: plan.id}
    |> RunPlan.new(queue: :terradesk)
    |> Oban.insert()
  end

  defp maybe_insert_job(_plan, false), do: {:ok, nil}
end
