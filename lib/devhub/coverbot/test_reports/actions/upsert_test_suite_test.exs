defmodule Devhub.Coverbot.TestReports.Actions.UpsertTestSuiteTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot
  alias Devhub.Coverbot.TestReports.Schemas.TestSuite

  test "upsert_test_suite/1" do
    %{id: organization_id} = insert(:organization)
    %{id: repository_id} = insert(:repository, organization_id: organization_id)
    %{id: repository_id_2} = insert(:repository, organization_id: organization_id, name: "repo_2")

    assert {:ok,
            %TestSuite{
              id: test_suite_id,
              name: "devhub_elixir",
              organization_id: ^organization_id,
              repository_id: ^repository_id,
              inserted_at: inserted_at,
              updated_at: updated_at
            }} =
             Coverbot.upsert_test_suite(%{
               name: "devhub_elixir",
               organization_id: organization_id,
               repository_id: repository_id
             })

    # If called again with the same params, the same struct is returned
    assert {:ok,
            %TestSuite{
              id: ^test_suite_id,
              name: "devhub_elixir",
              organization_id: ^organization_id,
              repository_id: ^repository_id,
              inserted_at: ^inserted_at,
              updated_at: ^updated_at
            }} =
             Coverbot.upsert_test_suite(%{
               name: "devhub_elixir",
               organization_id: organization_id,
               repository_id: repository_id
             })

    assert TestSuite |> Repo.all() |> length() == 1

    assert {:ok,
            %TestSuite{
              name: "other_name",
              organization_id: ^organization_id,
              repository_id: ^repository_id
            }} =
             Coverbot.upsert_test_suite(%{
               name: "other_name",
               organization_id: organization_id,
               repository_id: repository_id
             })

    # new name but same organization_id and repository_id, generates a new entry
    assert TestSuite |> Repo.all() |> length() == 2

    assert {:ok,
            %TestSuite{
              name: "devhub_elixir",
              organization_id: ^organization_id,
              repository_id: ^repository_id_2
            }} =
             Coverbot.upsert_test_suite(%{
               name: "devhub_elixir",
               organization_id: organization_id,
               repository_id: repository_id_2
             })

    # same name and organization but different repository_id, generates a new entry
    assert TestSuite |> Repo.all() |> length() == 3
  end
end
