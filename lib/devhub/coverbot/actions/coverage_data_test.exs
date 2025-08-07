defmodule Devhub.Coverbot.Actions.CoverageDataTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "coverage_data/1" do
    %{id: organization_id} = insert(:organization)
    %{id: repo_id} = insert(:repository, organization_id: organization_id)

    insert(:coverage,
      organization_id: organization_id,
      repository_id: repo_id,
      inserted_at: ~U[2024-01-01 00:00:00Z]
    )

    assert [%{date: ~N[2024-01-01 00:00:00.000000], percentage: 10.0}] =
             Coverbot.coverage_data(repo_id)
  end
end
