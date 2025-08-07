defmodule Devhub.TerraDesk.Jobs.RunDriftDetectionTest do
  use Devhub.DataCase, async: true

  import Ecto.Query

  alias Devhub.TerraDesk.Jobs.RunDriftDetection
  alias Devhub.TerraDesk.Schemas.Plan

  test "creates plans for correct workspaces" do
    organization = insert(:organization)
    schedule = insert(:terradesk_schedule, organization: organization)
    repository = insert(:repository, organization: organization)

    %{id: workspace_to_trigger_id} =
      insert(:workspace, organization: organization, repository: repository, schedules: [schedule])

    insert(:plan,
      workspace_id: workspace_to_trigger_id,
      organization: organization,
      schedule: schedule,
      inserted_at: DateTime.add(DateTime.utc_now(), -1, :day)
    )

    workspace_to_skip = insert(:workspace, organization: organization, repository: repository, schedules: [schedule])

    insert(:plan,
      workspace: workspace_to_skip,
      organization: organization,
      schedule: schedule,
      inserted_at: DateTime.add(DateTime.utc_now(), -1, :hour)
    )

    %{id: new_workspace_id} =
      insert(:workspace, organization: organization, repository: repository, schedules: [schedule])

    now = DateTime.utc_now()

    assert :ok = perform_job(RunDriftDetection, %{})

    query = from p in Plan, where: p.inserted_at > ^now, order_by: :inserted_at

    assert [
             %Plan{
               workspace_id: ^workspace_to_trigger_id
             },
             %Plan{
               workspace_id: ^new_workspace_id
             }
           ] = query |> Devhub.Repo.all() |> Enum.sort_by(& &1.workspace_id)
  end
end
