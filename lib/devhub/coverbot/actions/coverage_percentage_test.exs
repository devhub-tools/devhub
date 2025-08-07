defmodule Devhub.Coverbot.Actions.CoveragePercentageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "coverage_percentage/2" do
    %{id: organization_id} = insert(:organization)
    %{id: repo_id} = repo = insert(:repository, organization_id: organization_id)

    insert(:coverage,
      organization_id: organization_id,
      repository_id: repo_id
    )

    assert {:ok, Decimal.new("10")} == Coverbot.coverage_percentage(repo, "main")
    assert {:error, :coverage_not_found} = Coverbot.coverage_percentage(repo, "not found")
  end
end
