defmodule Devhub.Shared.Actions.DeleteLabelTest do
  use Devhub.DataCase, async: true

  alias Devhub.Shared
  alias Devhub.Shared.Schemas.Label

  test "successfully delete a label" do
    organization = insert(:organization)
    %{id: label_id} = label = insert(:label, organization: organization)

    assert {:ok, %Label{id: ^label_id}} = Shared.delete_label(label)
  end
end
