defmodule Devhub.Integrations.GitHub.StorageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Integrations.GitHub.Storage

  test "get_user/1" do
    %{id: organization_id} = insert(:organization)

    %{id: github_user_id} =
      insert(:github_user, username: "michaelst", organization_id: organization_id)

    insert(:organization_user,
      legal_name: "michael st clair",
      github_user_id: github_user_id,
      organization_id: organization_id
    )

    assert {:ok, %{id: ^github_user_id}} = Storage.get_user(id: github_user_id)
    assert {:error, :github_user_not_found} = Storage.get_user(id: "not found")
  end

  test "list_repositories/1" do
    %{id: organization_id} = insert(:organization)

    repo_1 =
      insert(:repository,
        organization_id: organization_id,
        name: "statistics",
        owner: "michael",
        pushed_at: ~U[2024-01-02 00:00:00Z]
      )

    repo_2 =
      insert(:repository,
        organization_id: organization_id,
        name: "companies",
        owner: "michael",
        pushed_at: ~U[2024-01-03 00:00:00Z]
      )

    repo_3 =
      insert(:repository,
        organization_id: organization_id,
        name: "organizations",
        owner: "michael",
        pushed_at: ~U[2024-01-04 00:00:00Z]
      )

    repo_4 =
      insert(:repository,
        organization_id: organization_id,
        name: "users",
        owner: "michael",
        pushed_at: ~U[2024-01-05 00:00:00Z]
      )

    assert [^repo_4, ^repo_3, ^repo_2, ^repo_1] = Storage.list_repositories(organization_id)
  end

  test "get_repository/1" do
    %{id: organization_id} = insert(:organization)

    repo =
      insert(:repository,
        organization_id: organization_id,
        name: "michaelst",
        owner: "michaelst",
        pushed_at: ~U[2024-03-01 00:00:00Z]
      )

    assert {:ok, ^repo} = Storage.get_repository(name: "michaelst")
    assert {:error, :repository_not_found} = Storage.get_repository(name: "not found")
  end

  test "update_repository/2" do
    %{id: organization_id} = insert(:organization)
    repo = insert(:repository, organization_id: organization_id)
    now = DateTime.truncate(DateTime.utc_now(), :second)

    attrs = %{
      pushed_at: now
    }

    assert {:ok,
            %Repository{
              pushed_at: ^now
            }} = Storage.update_repository(repo, attrs)
  end
end
