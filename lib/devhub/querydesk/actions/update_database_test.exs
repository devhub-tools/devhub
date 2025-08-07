defmodule Devhub.QueryDesk.Actions.UpdateDatabaseTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "success" do
    %{
      credentials: [
        %{id: first_cred_id, default_credential: true},
        # should be deleted
        %{id: second_cred_id}
      ]
    } =
      database =
      insert(:database,
        organization: build(:organization),
        credentials: [
          build(:database_credential, username: "first", default_credential: true),
          build(:database_credential, username: "second")
        ]
      )

    %{id: other_cred_id} =
      other_credential =
      insert(:database_credential,
        username: "other",
        default_credential: true,
        database: build(:database, organization: build(:organization))
      )

    params = %{
      "adapter" => "postgres",
      "agent_id" => "",
      "credential_drop" => ["1"],
      "credential_sort" => ["0", "1"],
      "credentials" => %{
        "0" => %{
          "_persistent_id" => "0",
          "default_credential" => "false",
          "id" => first_cred_id,
          "reviews_required" => "4",
          "username" => "first"
        },
        "1" => %{
          "_persistent_id" => "1",
          "default_credential" => "false",
          "id" => second_cred_id,
          "reviews_required" => "1",
          "username" => "second"
        },
        "2" => %{
          "_persistent_id" => "2",
          "default_credential" => "true",
          "reviews_required" => "1",
          "username" => "third",
          "password" => "password"
        },
        "3" => %{
          "_persistent_id" => "3",
          "default_credential" => "false",
          "id" => other_cred_id,
          "reviews_required" => "1",
          "username" => "fourth",
          "password" => "password"
        }
      },
      "database" => "devhub_dev",
      "group" => "",
      "hostname" => "127.0.0.1",
      "name" => "Devhub1",
      "restrict_access" => "true",
      "slack_channel" => "",
      "ssl" => "false"
    }

    assert {:ok,
            %{
              credentials: [
                %{id: ^first_cred_id, default_credential: false},
                %{username: "third", default_credential: true},
                %{id: fourth_id, username: "fourth", default_credential: false}
              ]
            }} = QueryDesk.update_database(database, params)

    # we should not allow stealing another accounts cred id
    refute fourth_id == other_cred_id

    assert %{credentials: [%{id: ^other_cred_id}]} =
             QueryDesk.Schemas.Database |> Repo.get(other_credential.database_id) |> Repo.preload(:credentials)
  end
end
