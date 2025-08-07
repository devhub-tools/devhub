defmodule Devhub.Shared.Actions.RemoveObjectLabelTest do
  use Devhub.DataCase, async: true

  alias Devhub.Shared

  describe "remove_object_label/1" do
    test "successfully remove object label" do
      %{id: organization_id} = organization = insert(:organization)
      label = insert(:label, organization: organization)
      saved_query = insert(:saved_query, organization: organization)
      insert(:labeled_object, label_id: label.id, saved_query_id: saved_query.id, organization_id: organization_id)

      assert {1, nil} = Shared.remove_object_label(label_id: label.id)
    end
  end
end
