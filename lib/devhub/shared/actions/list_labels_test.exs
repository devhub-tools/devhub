defmodule Devhub.Shared.Actions.ListLabelsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Shared

  test "successfully list labels" do
    %{id: organization_id} = organization = insert(:organization)
    %{name: label_name} = insert(:label, organization: organization)
    %{name: label_2_name} = insert(:label, organization: organization, name: "a")

    assert [%{name: ^label_2_name}, %{name: ^label_name}] =
             organization_id
             |> Shared.list_labels()
             |> Enum.sort_by(& &1.name)
  end
end
