defmodule Devhub.TerraDesk.Jobs.RunDriftDetection do
  @moduledoc false
  use Oban.Worker, queue: :terradesk

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan
  alias Devhub.TerraDesk.Schemas.Workspace
  alias Oban.Cron.Expression

  @impl Oban.Worker
  def perform(_job) do
    schedules = TerraDesk.list_schedules(filter: [enabled: true])

    Enum.each(schedules, &create_plans/1)
  end

  defp create_plans(schedule) do
    workspaces = lookup_workspaces(schedule)

    Enum.each(workspaces, fn workspace ->
      TerraDesk.create_plan(workspace, workspace.repository.default_branch, schedule_id: schedule.id, run: true)
    end)
  end

  defp lookup_workspaces(schedule) do
    latest_runs_query =
      from p in Plan,
        select: %{
          workspace_id: p.workspace_id,
          last_run: max(p.inserted_at)
        },
        where: p.schedule_id == ^schedule.id,
        group_by: p.workspace_id

    latest_runs =
      latest_runs_query
      |> Repo.all()
      |> Map.new(fn %{workspace_id: workspace_id, last_run: last_run} ->
        {workspace_id, last_run}
      end)

    query =
      from w in Workspace,
        join: o in assoc(w, :organization),
        join: s in assoc(w, :schedules),
        join: r in assoc(w, :repository),
        where: s.id == ^schedule.id,
        preload: [organization: o, repository: r]

    query
    |> Repo.all()
    |> Enum.filter(fn workspace ->
      if last_run = Map.get(latest_runs, workspace.id) do
        next_run = schedule.cron_expression |> Expression.parse!() |> Expression.next_at(last_run)
        DateTime.after?(DateTime.utc_now(), next_run)
      else
        true
      end
    end)
  end
end
