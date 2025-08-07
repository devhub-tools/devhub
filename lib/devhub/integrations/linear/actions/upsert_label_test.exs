defmodule Devhub.Integrations.Linear.Actions.UpsertLabelTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear
  alias Devhub.Integrations.Linear.Label

  test "upsert_label/1" do
    %{organization_id: organization_id} = integration = insert(:integration)

    params = %{
      "id" => "bcead8ed-ca46-43a8-ba6a-d2341f58948a",
      "name" => "Bug",
      "color" => "#FFFFFF",
      "isGroup" => false
    }

    assert {:ok,
            %Label{
              id: id,
              organization_id: ^organization_id,
              external_id: "bcead8ed-ca46-43a8-ba6a-d2341f58948a",
              name: "Bug",
              color: "#FFFFFF",
              type: :feature
            }} = Linear.upsert_label(integration, params)

    params = %{params | "color" => "#000000"}

    assert {:ok,
            %Label{
              id: ^id,
              color: "#000000"
            }} = Linear.upsert_label(integration, params)
  end
end
