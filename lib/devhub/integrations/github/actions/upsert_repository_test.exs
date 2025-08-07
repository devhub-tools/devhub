defmodule Devhub.Integrations.GitHub.Actions.UpsertRepositoryTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Repository

  test "upsert_repository/1" do
    %{id: organization_id} = insert(:organization)

    attrs = %{
      name: "velocity",
      owner: "michaelst",
      default_branch: "main",
      pushed_at: ~U[2016-05-24 13:26:08Z],
      organization_id: organization_id
    }

    assert {:ok,
            %Repository{
              id: id,
              name: "velocity",
              owner: "michaelst",
              pushed_at: ~U[2016-05-24 13:26:08Z],
              organization_id: ^organization_id
            }} = GitHub.upsert_repository(attrs)

    attrs = %{attrs | pushed_at: ~U[2016-06-24 13:26:08Z]}

    assert {:ok,
            %Repository{
              id: ^id,
              name: "velocity",
              owner: "michaelst",
              pushed_at: ~U[2016-06-24 13:26:08Z],
              organization_id: ^organization_id
            }} = GitHub.upsert_repository(attrs)
  end
end
