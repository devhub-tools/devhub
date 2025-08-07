defmodule Devhub.Coverbot.Actions.GetCoverageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "success" do
    organization = insert(:organization)

    %{id: coverage_id} =
      insert(:coverage, organization: organization, repository: build(:repository, organization: organization))

    assert {:ok, %{id: ^coverage_id}} = Coverbot.get_coverage(id: coverage_id, organization_id: organization.id)
  end

  test "not found" do
    assert {:error, :coverage_not_found} = Coverbot.get_coverage(id: "not-found")
  end
end
