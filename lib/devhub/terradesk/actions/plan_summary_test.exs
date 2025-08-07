defmodule Devhub.TerraDesk.Actions.PlanSummaryTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk

  test "parses summary correctly" do
    log = File.read!("test/support/terraform/plan-log.txt")

    plan = build(:plan, log: log)

    assert %{add: "3", change: "3", destroy: "1"} == TerraDesk.plan_summary(plan)
  end

  test "no changes" do
    log = """
    google_service_account_iam_binding.terradesk_workload_identity: Refreshing state... [id=projects/cloud-57/serviceAccounts/terradesk@cloud-57.iam.gserviceaccount.com/roles/iam.workloadIdentityUser]
    google_service_account_iam_binding.spendable_workload_identity: Refreshing state... [id=projects/cloud-57/serviceAccounts/spendable@cloud-57.iam.gserviceaccount.com/roles/iam.workloadIdentityUser]
    google_service_account_iam_binding.txferretrescue_workload_identity: Refreshing state... [id=projects/cloud-57/serviceAccounts/txferretrescue@cloud-57.iam.gserviceaccount.com/roles/iam.workloadIdentityUser]
    google_service_account_iam_binding.db_backups_workload_identity: Refreshing state... [id=projects/cloud-57/serviceAccounts/db-backups@cloud-57.iam.gserviceaccount.com/roles/iam.workloadIdentityUser]
    google_iam_workload_identity_pool_provider.blue_cluster: Refreshing state... [id=projects/cloud-57/locations/global/workloadIdentityPools/blue-cluster/providers/blue-cluster]

    No changes. Your infrastructure matches the configuration.

    Terraform has compared your real infrastructure against your configuration
    and found no differences, so no changes are needed.
    """

    plan = build(:plan, log: log)

    assert %{add: "0", change: "0", destroy: "0"} = TerraDesk.plan_summary(plan)
  end

  test "log is nil" do
    plan = build(:plan, log: nil)

    assert plan |> TerraDesk.plan_summary() |> is_nil()
  end
end
