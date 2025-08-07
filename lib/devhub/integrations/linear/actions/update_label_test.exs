defmodule Devhub.Integrations.Linear.Actions.UpdateLabelTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear
  alias Devhub.Integrations.Linear.Label

  test "update_user/2" do
    organization = insert(:organization)
    label = insert(:linear_label, organization: organization, type: :feature)

    params = %{
      type: "bug"
    }

    assert {:ok,
            %Label{
              type: :bug
            }} = Linear.update_label(label, params)
  end
end
