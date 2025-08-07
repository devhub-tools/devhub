defmodule Devhub.Workflows.Jobs.RunScheduledWorkflowsTest do
  use Devhub.DataCase, async: true

  import Ecto.Query

  alias Devhub.Workflows.Jobs.RunScheduledWorkflows
  alias Devhub.Workflows.Schemas.Run

  test "creates runs for correct workflows" do
    organization = insert(:organization)

    %{id: workflow_to_trigger_id} =
      insert(:workflow, organization: organization, cron_schedule: "0 0 * * *")

    insert(:workflow_run,
      workflow_id: workflow_to_trigger_id,
      organization_id: organization.id,
      inserted_at: DateTime.add(DateTime.utc_now(), -1, :day)
    )

    workflow_to_skip = insert(:workflow, organization: organization, cron_schedule: "0 0 * * *")

    insert(:workflow_run,
      workflow_id: workflow_to_skip.id,
      organization_id: organization.id,
      inserted_at: DateTime.add(DateTime.utc_now(), -1, :hour)
    )

    %{id: new_workflow_id} =
      insert(:workflow, organization: organization, cron_schedule: "0 0 * * *")

    now = DateTime.utc_now()

    assert :ok = perform_job(RunScheduledWorkflows, %{})

    query = from r in Run, where: r.inserted_at > ^now, order_by: :inserted_at

    assert [
             %Run{
               workflow_id: ^workflow_to_trigger_id
             },
             %Run{
               workflow_id: ^new_workflow_id
             }
           ] = query |> Devhub.Repo.all() |> Enum.sort_by(& &1.workflow_id)
  end
end
