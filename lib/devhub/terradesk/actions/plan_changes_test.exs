defmodule Devhub.TerraDesk.Actions.PlanChangesTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk

  test "parses changes correctly" do
    log = File.read!("test/support/terraform/plan-log.txt")

    plan = build(:plan, log: log)

    assert [
             %{
               name: "cloudflare_record.app_devhub",
               summary:
                 "<pre><text> cloudflare_record.app_devhub</text><text> will be </text><strong></strong><span style=\"color: red;\">destroyed</span></pre>",
               details: _rest1
             },
             %{
               name: "cloudflare_record.root_devhub[\"devhub\"]",
               summary:
                 "<pre><text> cloudflare_record.root_devhub[&quot;devhub&quot;]</text><text> will be updated in-place</text></pre>",
               details: _rest2
             },
             %{
               name: "google_iam_workload_identity_pool_provider.terradesk",
               summary:
                 "<pre><text> google_iam_workload_identity_pool_provider.terradesk</text><text> will be updated in-place</text></pre>",
               details: _rest3
             },
             %{
               name: "google_pubsub_subscription.dev_send_member_request[0]",
               summary:
                 "<pre><text> google_pubsub_subscription.dev_send_member_request[0]</text><text> will be created</text></pre>",
               details: _rest4
             },
             %{
               name: "google_pubsub_subscription.dev_send_notification_request",
               summary:
                 "<pre><text> google_pubsub_subscription.dev_send_notification_request</text><text> will be created</text></pre>",
               details: _rest5
             },
             %{
               name: "google_pubsub_subscription.send_notification_request",
               summary:
                 "<pre><text> google_pubsub_subscription.send_notification_request</text><text> will be created</text></pre>",
               details: _rest6
             },
             %{
               name: "google_service_account_iam_binding.terradesk_workload_identity",
               summary:
                 "<pre><text> google_service_account_iam_binding.terradesk_workload_identity</text><text> will be updated in-place</text></pre>",
               details: _rest7
             }
           ] = TerraDesk.plan_changes(plan)
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

    assert plan |> TerraDesk.plan_changes() |> Enum.empty?()
  end
end
