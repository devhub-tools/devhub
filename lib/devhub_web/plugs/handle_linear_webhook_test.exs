defmodule DevhubWeb.Plugs.HandleLinearWebhookTest do
  use DevhubWeb.ConnCase, async: true

  alias Devhub.Integrations.Linear.Issue
  alias Devhub.Integrations.Linear.Issue.State
  alias Devhub.Integrations.Linear.Label
  alias Devhub.Integrations.Linear.Project
  alias Devhub.Integrations.Linear.User

  describe "users" do
    test "create", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      body = File.read!("test/support/linear/create_user.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "ba3fb6aa045a407547e386b3d40818df98d7bbe902caf48254f3dc92870b7c34"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      assert [
               %User{
                 external_id: "ef7da9e2-9714-43d3-ae57-c61f3f4fa0ae",
                 name: "Michael St Clair"
               }
             ] = Devhub.Repo.all(User)
    end

    test "update", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      %{id: user_id} =
        insert(:linear_user, organization: organization, external_id: "47dc977b-e6d6-4def-a821-82876f9d3fcd")

      body = File.read!("test/support/linear/update_user.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "68b00dc6b8e25453570575442e1dd22b4d9ab8d9e34067ee442d10fcbfce261b"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      assert [
               %User{
                 id: ^user_id,
                 external_id: "47dc977b-e6d6-4def-a821-82876f9d3fcd",
                 name: "Brianna"
               }
             ] = Devhub.Repo.all(User)
    end
  end

  describe "issues" do
    test "create", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      body = File.read!("test/support/linear/create_issue.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "909b171cc25a597786b1fde6758d7e263067376e25fba8125d3c8dac1a856c2b"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      assert [
               %Issue{
                 archived_at: nil,
                 canceled_at: nil,
                 completed_at: nil,
                 created_at: ~U[2024-06-07 21:43:46Z],
                 estimate: nil,
                 external_id: "bd026a9c-3b1d-4697-a1c3-40e148236a49",
                 identifier: "DVOPS-1380",
                 started_at: ~U[2024-06-07 21:43:46Z],
                 title: "test",
                 url: "https://linear.app/pdq/issue/DVOPS-1380/test",
                 state: %State{
                   id: "d18ce2aa-c088-457f-8412-715e271b039e",
                   color: "#f2c94c",
                   name: "In Progress",
                   type: "started"
                 }
               }
             ] = Devhub.Repo.all(Issue)
    end

    test "update", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      insert(:linear_label, organization: organization, external_id: "6db94ee8-8eb9-40c1-b695-a4e9b09b2cdc")

      body = File.read!("test/support/linear/update_issue.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "c9e0cfa7481a5e79bd5eddee06358d99cf3b5731f04bae0244051b75b139f9f0"
             )
             |> post("/webhook/linear", body)
             |> response(200)
    end

    test "remove", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      issue =
        insert(:linear_issue,
          organization: organization,
          external_id: "bd026a9c-3b1d-4697-a1c3-40e148236a49"
        )

      assert Devhub.Repo.get(Issue, issue.id)

      body = File.read!("test/support/linear/remove_issue.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "a21a6883050dfabe964bc3f63b3bf1b968251f43495164d685ae38edb3fb8fea"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      refute Devhub.Repo.get(Issue, issue.id)
    end
  end

  describe "projects" do
    test "create", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      body = File.read!("test/support/linear/create_project.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "c0211f7fac26de08bc3aa130c14f00b02713116a9157983f309b5f014b0bb543"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      assert [
               %Project{
                 archived_at: nil,
                 canceled_at: nil,
                 completed_at: nil,
                 created_at: ~U[2025-01-27 12:38:32Z],
                 external_id: "484a02d8-fe2b-4334-ba52-a5ec2e1c3b97",
                 name: "webhook test",
                 status: "Backlog"
               }
             ] = Devhub.Repo.all(Project)
    end

    test "update", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      %{id: project_id} =
        insert(:project,
          organization: organization,
          external_id: "484a02d8-fe2b-4334-ba52-a5ec2e1c3b97",
          name: "project"
        )

      body = File.read!("test/support/linear/update_project.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "afb233da08eb6e470299985ada42eb64f2d06fdfca396e2c7dd73fa201ebac0a"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      assert [
               %Project{
                 id: ^project_id,
                 archived_at: nil,
                 canceled_at: nil,
                 completed_at: nil,
                 created_at: ~U[2025-01-27 12:38:32Z],
                 external_id: "484a02d8-fe2b-4334-ba52-a5ec2e1c3b97",
                 name: "webhook test",
                 status: "Backlog"
               }
             ] = Devhub.Repo.all(Project)
    end

    test "remove", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      project =
        insert(:project,
          organization: organization,
          external_id: "484a02d8-fe2b-4334-ba52-a5ec2e1c3b97"
        )

      assert Devhub.Repo.get(Project, project.id)

      body = File.read!("test/support/linear/remove_project.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "da17fab575b67efd8d435123aa147d68517e9673e186544029674242add587ba"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      refute Devhub.Repo.get(Project, project.id)
    end
  end

  describe "labels" do
    test "create", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      body = File.read!("test/support/linear/create_label.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "34309d7b3534eeccc208d1ad65cd6185bb8788e00550168c48c318f54405c987"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      assert [
               %Label{
                 external_id: "3c0f3b5a-147f-4527-9d39-2e39de41fbeb",
                 name: "Test",
                 color: "#4cb782",
                 type: :feature
               }
             ] = Devhub.Repo.all(Label)
    end

    test "update", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      %{id: label_id} =
        insert(:linear_label,
          organization: organization,
          external_id: "3c0f3b5a-147f-4527-9d39-2e39de41fbeb",
          color: "#ffffff"
        )

      body = File.read!("test/support/linear/update_label.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "128cb03bbaf9e659c8b80f5837940b9fe66035694da6b616d64a0e120cd307eb"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      assert [
               %Label{
                 id: ^label_id,
                 external_id: "3c0f3b5a-147f-4527-9d39-2e39de41fbeb",
                 name: "Test",
                 color: "#26b5ce",
                 type: :feature
               }
             ] = Devhub.Repo.all(Label)
    end

    test "remove", %{conn: conn, organization: organization} do
      insert(:integration,
        organization: organization,
        provider: :linear,
        external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
        access_token: Jason.encode!(%{webhook_secret: "secret"})
      )

      label =
        insert(:linear_label,
          organization: organization,
          external_id: "3c0f3b5a-147f-4527-9d39-2e39de41fbeb"
        )

      assert Devhub.Repo.get(Label, label.id)

      body = File.read!("test/support/linear/remove_label.json")

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header(
               "linear-signature",
               "cc9711a6f0e725ce64281ad47b9c89845946ed3d9dc302913b87da1fe75ae0a4"
             )
             |> post("/webhook/linear", body)
             |> response(200)

      refute Devhub.Repo.get(Label, label.id)
    end
  end

  test "rejects invalid signature", %{conn: conn, organization: organization} do
    insert(:integration,
      organization: organization,
      provider: :linear,
      external_id: "0488de27-d717-40e9-bf6f-f2fe96e08d8a",
      access_token: Jason.encode!(%{webhook_secret: "different"})
    )

    body = File.read!("test/support/linear/update_issue.json")

    assert conn
           |> put_req_header("content-type", "application/json")
           |> put_req_header(
             "linear-signature",
             "b11ab4248628ef11e71d7ee0c042e0c1df83563c24d83b58b004bd95e15c0bc9"
           )
           |> post("/webhook/linear", body)
           |> response(403)
  end
end
