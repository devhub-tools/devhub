defmodule Devhub.Integrations.Linear.Actions.UpsertProjectTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear
  alias Devhub.Integrations.Linear.Project

  test "upsert_project/1" do
    %{organization_id: organization_id} = integration = insert(:integration)

    params = %{
      "id" => "bcead8ed-ca46-43a8-ba6a-d2341f58948a",
      "name" => "Developer Portal v1",
      "createdAt" => "2024-04-01T00:00:00Z",
      "archivedAt" => nil,
      "completedAt" => nil,
      "canceledAt" => nil,
      "status" => %{"name" => "In Progress"}
    }

    assert {:ok,
            %Project{
              id: id,
              organization_id: ^organization_id,
              external_id: "bcead8ed-ca46-43a8-ba6a-d2341f58948a",
              name: "Developer Portal v1",
              created_at: ~U[2024-04-01 00:00:00Z],
              status: "In Progress"
            }} = Linear.upsert_project(integration, params)

    params = Map.put(params, "status", %{"name" => "Backlog"})

    assert {:ok,
            %Project{
              id: ^id,
              status: "Backlog"
            }} = Linear.upsert_project(integration, params)
  end
end
