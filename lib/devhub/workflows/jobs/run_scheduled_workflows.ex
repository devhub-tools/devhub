defmodule Devhub.Workflows.Jobs.RunScheduledWorkflows do
  @moduledoc false
  use Oban.Worker, queue: :workflows

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Run
  alias Devhub.Workflows.Schemas.Workflow
  alias Oban.Cron.Expression

  @impl Oban.Worker
  def perform(_job) do
    workflows = lookup_workflows()

    Enum.each(workflows, fn workflow ->
      Devhub.Workflows.run_workflow(workflow, %{})
    end)
  end

  defp lookup_workflows do
    latest_runs_query =
      from r in Run,
        select: %{
          workflow_id: r.workflow_id,
          last_run: max(r.inserted_at)
        },
        group_by: r.workflow_id

    latest_runs =
      latest_runs_query
      |> Repo.all()
      |> Map.new(fn %{workflow_id: workflow_id, last_run: last_run} ->
        {workflow_id, last_run}
      end)

    query =
      from w in Workflow,
        left_join: s in assoc(w, :steps),
        where: not is_nil(w.cron_schedule),
        preload: [steps: s]

    query
    |> Repo.all()
    |> Enum.filter(fn workflow ->
      if last_run = Map.get(latest_runs, workflow.id) do
        next_run = workflow.cron_schedule |> Expression.parse!() |> Expression.next_at(last_run)
        DateTime.after?(DateTime.utc_now(), next_run)
      else
        true
      end
    end)
  end
end
