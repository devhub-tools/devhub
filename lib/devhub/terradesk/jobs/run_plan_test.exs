defmodule Devhub.TerraDesk.Jobs.RunPlanTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Jobs.RunPlan

  test "runs plan" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))

    %{id: plan_id} = plan = insert(:plan, workspace: workspace, organization: organization)

    expect(TerraDesk, :run_plan, fn %{id: ^plan_id} -> {:ok, plan} end)

    assert :ok = perform_job(RunPlan, %{"id" => plan_id})
  end

  test "doesn't run canceled plan" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))

    %{id: plan_id} = insert(:plan, workspace: workspace, organization: organization, status: :canceled)

    reject(&TerraDesk.run_plan/1)

    assert :ok = perform_job(RunPlan, %{"id" => plan_id})
  end
end
