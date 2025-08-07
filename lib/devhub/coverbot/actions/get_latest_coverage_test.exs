defmodule Devhub.Coverbot.Actions.GetLatestCoverageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot
  alias Devhub.Coverbot.Coverage

  test "get_latest_coverage/2" do
    %{id: organization_id} = insert(:organization)
    %{id: repo_id} = repo = insert(:repository, organization_id: organization_id)

    %{id: coverage_id} =
      insert(:coverage,
        organization_id: organization_id,
        repository_id: repo_id,
        inserted_at: ~U[2024-04-01 00:00:00Z],
        updated_at: ~U[2024-04-02 00:00:00Z]
      )

    insert(:coverage,
      organization_id: organization_id,
      repository_id: repo_id,
      inserted_at: ~U[2023-10-01 00:00:00Z],
      updated_at: ~U[2023-10-02 00:00:00Z]
    )

    assert {:ok,
            %Coverage{
              id: ^coverage_id,
              organization_id: ^organization_id,
              repository_id: ^repo_id
            }} = Coverbot.get_latest_coverage(repo, "main")

    assert {:error, :coverage_not_found} = Coverbot.get_latest_coverage(repo, "not found")
  end
end
