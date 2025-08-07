defmodule Devhub.Coverbot.Actions.ListCoverageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "list_coverage/1" do
    %{id: organization_id} = org = insert(:organization)

    %{id: repo_id} =
      insert(:repository,
        organization_id: organization_id,
        name: "users",
        owner: "michaelst",
        pushed_at: ~U[2023-10-01 00:00:00Z]
      )

    insert(:coverage, organization_id: organization_id, repository_id: repo_id)

    assert [
             %{
               id: repo_id,
               name: "users",
               owner: "michaelst",
               ref: "refs/heads/main",
               percentage: Decimal.new("10")
             }
           ] == Coverbot.list_coverage(org)
  end
end
