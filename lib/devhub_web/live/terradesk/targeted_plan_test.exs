defmodule DevhubWeb.Live.TerraDesk.TargetedPlanTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan

  @tag with_mfa: true
  test "LIVE /terradesk/workspaces/:id/plan", %{conn: conn, organization: organization} do
    workspace =
      insert(:workspace,
        organization: organization,
        required_approvals: 1,
        repository: build(:repository, organization: organization)
      )

    expect(TerraDesk, :list_terraform_resources, fn _workspace ->
      [
        "cloudflare_record.app_devhub",
        "google_iam_workload_identity_pool_provider.terradesk",
        "google_pubsub_subscription.dev_send_member_request[0]"
      ]
    end)

    {:ok, view, _html} = live(conn, ~p"/terradesk/workspaces/#{workspace.id}/plan")

    render_async(view)

    view
    |> element(~s(form[phx-change="select_resources"]))
    |> render_change(%{
      "cloudflare_record.root_devhub%5B%22devhub%22%5D" => "true",
      "google_iam_workload_identity_pool_provider.terradesk" => "false",
      "google_pubsub_subscription.dev_send_member_request%5B0%5D" => "true"
    })

    assert {:error, {:live_redirect, %{kind: :push, to: "/terradesk/plans/" <> plan_id}}} =
             view
             |> element(~s(button[phx-click="run_plan"]))
             |> render_click()

    assert %Plan{
             targeted_resources: [
               "cloudflare_record.root_devhub[\"devhub\"]",
               "google_pubsub_subscription.dev_send_member_request[0]"
             ]
           } = Devhub.Repo.get(Plan, plan_id)
  end
end
