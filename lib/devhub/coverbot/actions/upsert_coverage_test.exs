defmodule Devhub.Coverbot.Actions.UpsertCoverageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "upsert_coverage/2" do
    %{id: organization_id} = insert(:organization)
    %{id: repo_id} = insert(:repository, organization_id: organization_id)

    params = %{
      organization_id: organization_id,
      repository_id: repo_id,
      is_for_default_branch: true,
      sha: "1234",
      ref: "123",
      covered: 65,
      relevant: 42,
      percentage: Decimal.new("65")
    }

    assert {:ok,
            %{
              id: coverage_id,
              is_for_default_branch: true,
              sha: "1234",
              ref: "123",
              covered: 65,
              relevant: 42,
              percentage: percentage,
              organization_id: ^organization_id,
              repository_id: ^repo_id
            }} =
             Coverbot.upsert_coverage(params)

    assert Decimal.equal?(percentage, 65)

    params = %{
      organization_id: organization_id,
      repository_id: repo_id,
      is_for_default_branch: true,
      sha: "1234",
      ref: "123",
      covered: 50,
      relevant: 100,
      percentage: Decimal.new("50")
    }

    assert {:ok,
            %{
              id: ^coverage_id,
              is_for_default_branch: true,
              sha: "1234",
              ref: "123",
              covered: 50,
              relevant: 100,
              percentage: percentage,
              organization_id: ^organization_id,
              repository_id: ^repo_id
            }} =
             Coverbot.upsert_coverage(params)

    assert Decimal.equal?(percentage, 50)
  end
end
