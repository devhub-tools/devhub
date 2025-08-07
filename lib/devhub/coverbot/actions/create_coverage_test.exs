defmodule Devhub.Coverbot.Actions.CreateCoverageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot
  alias Devhub.Coverbot.Coverage

  test "create_coverage/1" do
    %{id: organization_id} = insert(:organization)

    %{id: repo_id} =
      insert(:repository,
        organization_id: organization_id,
        name: "michael",
        owner: "michaelst",
        pushed_at: ~U[2024-01-01 00:00:00Z]
      )

    percentage = Decimal.new("10")

    attrs = %{
      is_for_default_branch: false,
      sha: "ab4dvdc45454vdzdff",
      ref: "ref/heads/main",
      covered: 10,
      relevant: 100,
      percentage: percentage,
      organization_id: organization_id,
      repository_id: repo_id
    }

    assert {:ok,
            %Coverage{
              is_for_default_branch: false,
              sha: "ab4dvdc45454vdzdff",
              ref: "ref/heads/main",
              covered: 10,
              relevant: 100,
              percentage: ^percentage,
              organization_id: ^organization_id,
              repository_id: ^repo_id
            }} = Coverbot.create_coverage(attrs)
  end
end
