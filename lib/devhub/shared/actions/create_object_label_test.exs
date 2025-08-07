defmodule Devhub.Shared.Actions.CreateObjectLabelTest do
  use Devhub.DataCase, async: true

  alias Devhub.Shared
  alias Devhub.Shared.Schemas.LabeledObject

  describe "create_object_label/1" do
    test "successfully create a labeled object" do
      %{id: organization_id} = organization = insert(:organization)
      %{id: label_id} = insert(:label, organization: organization)
      %{id: saved_query_id} = insert(:saved_query, organization: organization)

      params = %{
        label_id: label_id,
        saved_query_id: saved_query_id,
        organization_id: organization_id
      }

      assert {:ok,
              %LabeledObject{label_id: ^label_id, saved_query_id: ^saved_query_id, organization_id: ^organization_id}} =
               Shared.create_object_label(params)
    end

    test "fail to create labeled object" do
      %{id: organization_id} = insert(:organization)

      params = %{organization: organization_id}

      assert {:error, %Ecto.Changeset{}} = Shared.create_object_label(params)
    end
  end
end
