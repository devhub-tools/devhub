defmodule Devhub.Shared.Actions.InsertOrUpdateLabelTest do
  @moduledoc false
  use Devhub.DataCase, async: true

  alias Devhub.Shared
  alias Devhub.Shared.Schemas.Label

  describe "successfully insert or update a label" do
    test "insert a new label" do
      organization = insert(:organization)

      assert {:ok, %Label{name: "test"}} =
               Shared.insert_or_update_label(%Label{organization_id: organization.id}, %{"name" => "test"})
    end

    test "update an existing label" do
      organization = insert(:organization)
      label = insert(:label, organization: organization, name: "test")

      assert {:ok, %Label{name: "test2"}} =
               Shared.insert_or_update_label(label, %{"name" => "test2"})
    end

    test "upsert" do
      %{id: organization_id} = organization = insert(:organization)
      %{id: label_id} = insert(:label, organization: organization, name: "test")

      assert {:ok, %Label{id: ^label_id}} =
               Shared.insert_or_update_label(%Label{organization_id: organization_id}, %{"name" => "test"})
    end
  end
end
