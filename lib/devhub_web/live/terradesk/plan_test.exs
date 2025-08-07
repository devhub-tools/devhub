defmodule DevhubWeb.Live.TerraDesk.PlanTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Integrations.Kubernetes.Client
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Jobs.RunPlan
  alias Devhub.TerraDesk.Schemas.Plan

  @tag with_mfa: true
  test "LIVE /terradesk/plan/:id", %{conn: conn, organization: organization} do
    workspace =
      insert(:workspace,
        organization: organization,
        required_approvals: 1,
        repository: build(:repository, organization: organization)
      )

    %{id: plan_id} =
      insert(:plan,
        workspace: workspace,
        organization: organization,
        status: :planned,
        log: File.read!("test/support/terraform/plan-log.txt")
      )

    {:ok, view, _html} = live(conn, ~p"/terradesk/plans/#{plan_id}")

    refute has_element?(view, ~s(button[phx-click="run_apply"]))

    expect(Wax, :new_authentication_challenge, fn _opts ->
      Map.put(
        Wax.new_authentication_challenge(),
        :bytes,
        <<24, 117, 127, 248, 106, 176, 81, 166, 136, 189, 216, 13, 253, 13, 54, 80, 111, 231, 158, 86, 203, 71, 183, 141,
          131, 148, 55, 105, 245, 20, 162, 188>>
      )
    end)

    view
    |> element(~s(button[phx-click="approve_plan"]))
    |> render_click()

    assert_push_event(view, "start_passkey_authentication", %{
      phxEvent: _phxEvent,
      challenge: _challenge,
      credIds: _credIds
    })

    params = %{
      "authenticatorData" => "SZYN5YgOjGh0NBcPZHZgW4/krrmihjLHmVzzuoMdl2MdAAAAAA==",
      "clientDataJSON" =>
        ~s({"type":"webauthn.get","challenge":"GHV_-GqwUaaIvdgN_Q02UG_nnlbLR7eNg5Q3afUUorw","origin":"http://localhost:4000","crossOrigin":false}),
      "rawId" => "2fomAYPOXkoe32isN3nAuotahwQ=",
      "sig" => "MEUCIQCU17iE5STV9waFu2GAnXl+zOGb3WFxjqpFBVeOhbOGlgIgTd5Ashoa9StHF8JxjBkj1Ysph8Du+qwlKLb6N9gbaSs=",
      "type" => "public-key"
    }

    assert render_hook(view, "approve_plan", params) =~ "1 / 1"

    assert has_element?(view, ~s(button[phx-click="run_apply"]))

    # create new targeted plan
    view
    |> element(~s(form[phx-change="select_resources"]))
    |> render_change(%{
      "cloudflare_record.root_devhub%5B%22devhub%22%5D" => "true",
      "google_iam_workload_identity_pool_provider.terradesk" => "false==`",
      "google_pubsub_subscription.dev_send_member_request%5B0%5D" => "true"
    })

    assert {:error, {:live_redirect, %{kind: :push, to: "/terradesk/plans/" <> plan_id}}} =
             view
             |> element(~s(button[phx-click="new_targeted_plan"]))
             |> render_click()

    assert %Plan{
             targeted_resources: [
               "cloudflare_record.root_devhub[\"devhub\"]",
               "google_pubsub_subscription.dev_send_member_request[0]"
             ]
           } = Devhub.Repo.get(Plan, plan_id)
  end

  test "retry plan", %{conn: conn, organization: organization} do
    workspace =
      insert(:workspace,
        organization: organization,
        required_approvals: 1,
        repository: build(:repository, organization: organization)
      )

    %{id: plan_id} =
      insert(:plan,
        workspace: workspace,
        organization: organization,
        status: :failed
      )

    {:ok, view, _html} = live(conn, ~p"/terradesk/plans/#{plan_id}")

    expect(Client, :delete_job, fn _name -> :ok end)

    view
    |> element(~s(button[phx-click="retry_plan"]))
    |> render_click()

    assert_enqueued worker: RunPlan, args: %{id: plan_id}
  end

  test "cancel plan", %{conn: conn, organization: organization} do
    workspace =
      insert(:workspace,
        organization: organization,
        required_approvals: 1,
        repository: build(:repository, organization: organization)
      )

    %{id: plan_id} =
      plan =
      insert(:plan,
        workspace: workspace,
        organization: organization,
        status: :running
      )

    {:ok, view, _html} = live(conn, ~p"/terradesk/plans/#{plan_id}")

    expect(TerraDesk, :cancel_plan, fn %{id: ^plan_id} -> {:ok, plan} end)

    view
    |> element(~s(button[phx-click="cancel_plan"]))
    |> render_click() =~ "canceled"
  end
end
