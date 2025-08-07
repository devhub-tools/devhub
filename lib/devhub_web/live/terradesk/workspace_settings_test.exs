defmodule DevhubWeb.Live.TerraDesk.WorkspaceSettingsTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Integrations.Google

  setup do
    stub(Google, :workload_identity_claims, fn _workspace_id ->
      """
      {
        "aud": "https://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/providers/${PROVIDER}",
        "exp": 1728678437,
        "iat": 1728678377,
        "iss": "https://devhub.local",
        "jti": "2vunvkqrhrrelp0i54000in2",
        "nbf": 1728678377,
        "sub": "workspace:tfws_01J9AVJ131RG6CP4Y2VK3C6SHK",
        "terradesk_workspace_id": "tfws_01J9AVJ131RG6CP4Y2VK3C6SHK"
      }
      """
    end)

    :ok
  end

  test "loads", %{conn: conn, organization: organization} do
    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        secrets: [%{name: "MYSECRET", value: "secret"}],
        env_vars: [%{name: "MYENVVAR", value: "envvar"}],
        workload_identity: %{
          organization: organization,
          enabled: true,
          pool: "pool",
          provider: "provider"
        }
      )

    insert(:plan,
      workspace: workspace,
      organization: organization,
      status: :planned,
      log: File.read!("test/support/terraform/plan-log.txt")
    )

    {:ok, _view, html} = live(conn, ~p"/terradesk/workspaces/#{workspace.id}/settings")

    assert html =~ workspace.name
  end

  test "can't use another orgs repository", %{conn: conn, organization: organization} do
    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization)
      )

    {:ok, view, _html} = live(conn, ~p"/terradesk/workspaces/#{workspace.id}/settings")

    # right now can't test multiple orgs, but can simulate it by adding after page loads the ids
    repo_added_after_load = insert(:repository, organization: organization, name: "other org")

    assert view
           |> element(~s(form[phx-change=update_changeset]))
           |> render_change(%{workspace: %{repository_id: repo_added_after_load.id}}) =~ "Invalid repository selected."
  end
end
