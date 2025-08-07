defmodule Devhub.Agents.Actions.CreateTest do
  use Devhub.DataCase, async: true

  alias Devhub.Agents

  test "success" do
    %{id: organization_id} = organization = insert(:organization)
    assert {:ok, %{name: "test", organization_id: ^organization_id}} = Agents.create("test", organization)
  end

  test "errors if orgnization is nil" do
    assert {
             :error,
             %Ecto.Changeset{errors: [organization_id: {"can't be blank", [validation: :required]}]}
           } = Agents.create("test", %{id: nil})
  end
end
