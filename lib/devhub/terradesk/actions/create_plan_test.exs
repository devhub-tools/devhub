defmodule Devhub.TerraDesk.Actions.CreatePlanTest do
  use Devhub.DataCase, async: true

  import ExUnit.CaptureLog

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Jobs.RunPlan
  alias Devhub.TerraDesk.Schemas.Plan

  test "enqueues job based on setting" do
    organization = insert(:organization)

    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        run_plans_automatically: true
      )

    # should cancel queued plans
    queued_plan = insert(:plan, workspace: workspace, organization: organization, status: :queued)

    assert {:ok,
            %Plan{
              id: plan_id,
              github_branch: "main",
              user: nil,
              workspace: ^workspace,
              organization: ^organization
            }} = TerraDesk.create_plan(workspace, "main")

    assert_enqueued worker: RunPlan, args: %{id: plan_id}

    assert {:ok, %Plan{status: :canceled}} = TerraDesk.get_plan(id: queued_plan.id)
  end

  test "doesn't job based on setting" do
    organization = insert(:organization)

    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        run_plans_automatically: false
      )

    assert {:ok,
            %Plan{
              id: plan_id,
              github_branch: "main",
              user: nil,
              workspace: ^workspace,
              organization: ^organization
            }} = TerraDesk.create_plan(workspace, "main")

    refute_enqueued worker: RunPlan, args: %{id: plan_id}
  end

  test "success overriding defaults" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))
    user = insert(:user)

    assert {:ok,
            %Plan{
              github_branch: "main",
              user: ^user,
              workspace: ^workspace,
              organization: ^organization
            }} = TerraDesk.create_plan(workspace, "main", user: user, targeted_resources: ["test_resource.name"])
  end

  test "handles changeset error" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))

    assert capture_log(fn ->
             assert {
                      :error,
                      %Ecto.Changeset{errors: [github_branch: {"can't be blank", [validation: :required]}]}
                    } = TerraDesk.create_plan(workspace, "")
           end) =~ "Failed to create plan: #Ecto.Changeset"
  end
end
