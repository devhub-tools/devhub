defmodule Devhub.Integrations.Linear.Actions.ListLabelsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear

  test "list_labels/1" do
    organization = insert(:organization)
    other_organization = insert(:organization)

    linear_label_ids = 3 |> insert_list(:linear_label, organization: organization) |> Enum.map(& &1.id)
    insert(:linear_label, organization: other_organization)

    linear_labels = Linear.list_labels(organization.id)
    assert length(linear_labels) == 3
    assert Enum.all?(linear_labels, &(&1.id in linear_label_ids))
  end
end
