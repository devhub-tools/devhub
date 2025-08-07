defmodule Devhub.TerraDesk.Actions.CancelPlanTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Kubernetes
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan

  test "runs plan" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))
    insert(:integration, organization: organization, provider: :github)

    plan =
      insert(:plan,
        workspace: workspace,
        organization: organization,
        status: :running,
        commit_sha: "123456789"
      )

    job_name = "plan-#{plan.id}" |> String.replace("_", "-") |> String.downcase()

    expect(Kubernetes.Client, :delete_job, fn ^job_name ->
      :ok
    end)

    expect(GitHub.Client, :create_check, fn _integration, _repository, _details ->
      TeslaHelper.response([])
    end)

    assert {:ok, %Plan{status: :canceled}} = TerraDesk.cancel_plan(plan)
  end
end
