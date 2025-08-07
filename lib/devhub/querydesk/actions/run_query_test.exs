defmodule Devhub.QueryDesk.Actions.RunQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "local" do
    organization = insert(:organization)
    user = insert(:user)
    organization_user = insert(:organization_user, organization: organization, user: user)

    credential =
      insert(:database_credential,
        default_credential: true,
        database:
          build(:database,
            organization: organization,
            permissions: [build(:object_permission, permission: :write, organization_user: organization_user)]
          )
      )

    query =
      insert(:query,
        user: user,
        organization: organization,
        credential: credential,
        query: "SELECT * FROM schema_migrations ORDER BY version LIMIT 100;"
      )

    assert {:ok, result, query} = QueryDesk.run_query(query)

    assert %{
             columns: ["version", "inserted_at"],
             rows: [[20_240_321_034_813, _name] | _rest]
           } = result

    assert %{
             failed: false,
             executed_at: executed_at
           } = query

    refute is_nil(executed_at)

    assert {:error, "Query was already executed."} = QueryDesk.run_query(query)
  end

  test "can run multiple queries" do
    organization = insert(:organization)
    user = insert(:user)
    organization_user = insert(:organization_user, organization: organization, user: user)

    credential =
      insert(:database_credential,
        default_credential: true,
        database:
          build(:database,
            organization: organization,
            permissions: [build(:object_permission, permission: :write, organization_user: organization_user)]
          )
      )

    query =
      insert(:query,
        user: user,
        organization: organization,
        credential: credential,
        query: """
        SELECT * FROM schema_migrations ORDER BY version LIMIT 100;
        UPDATE users SET updated_at = now();
        """
      )

    assert {:ok, ["select 100", "update 0"], query} = QueryDesk.run_query(query)

    assert %{
             failed: false,
             executed_at: executed_at
           } = query

    refute is_nil(executed_at)
  end

  test "streaming" do
    organization = insert(:organization)
    user = insert(:user)
    organization_user = insert(:organization_user, organization: organization, user: user)

    credential =
      insert(:database_credential,
        default_credential: true,
        database:
          build(:database,
            organization: organization,
            permissions: [build(:object_permission, permission: :write, organization_user: organization_user)]
          )
      )

    query =
      insert(:query,
        user: user,
        organization: organization,
        credential: credential,
        query: "SELECT * FROM schema_migrations ORDER BY version LIMIT 20;"
      )

    Phoenix.PubSub.subscribe(Devhub.PubSub, query.id)

    assert {:ok, {:stream, _task}, _query} = QueryDesk.run_query(query, stream?: true)

    assert_receive {:query_stream, {:chunk, {:ok, first_binary}}}, 1000

    assert %{
             "columns" => ["version", "inserted_at"],
             "command" => "stream",
             "num_rows" => 10,
             "rows" => [
               [[20_240_321_034_813, "integer", true], [_inserted_at, "datetime", true]]
               | _rest
             ]
           } = first_binary |> :brotli.decode() |> elem(1) |> Jason.decode!()

    assert_receive {:query_stream, {:chunk, {:ok, second_binary}}}, 1000

    assert %{
             "columns" => ["version", "inserted_at"],
             "command" => "stream",
             "num_rows" => 10,
             "rows" => [
               [[20_240_720_044_524, "integer", true], [_inserted_at, "datetime", true]]
               | _rest
             ]
           } = second_binary |> :brotli.decode() |> elem(1) |> Jason.decode!()

    assert_receive {:query_stream, :done}
  end

  test "clickhouse" do
    organization = insert(:organization)
    user = insert(:user)
    organization_user = insert(:organization_user, organization: organization, user: user)

    credential =
      insert(:database_credential,
        default_credential: true,
        username: "default",
        password: "clickhouse",
        database:
          build(:database,
            organization: organization,
            permissions: [build(:object_permission, permission: :write, organization_user: organization_user)],
            adapter: :clickhouse,
            database: "system"
          )
      )

    query =
      insert(:query,
        user: user,
        organization: organization,
        credential: credential,
        query: "SELECT database, name FROM system.tables LIMIT 20;"
      )

    Phoenix.PubSub.subscribe(Devhub.PubSub, query.id)

    assert {:ok, {:stream, _task}, _query} = QueryDesk.run_query(query, stream?: true)

    assert_receive {:query_stream, {:chunk, {:ok, first_binary}}}, 1000

    assert %{
             "columns" => ["database", "name"],
             "command" => "select",
             "num_rows" => 10,
             "rows" => [
               [["INFORMATION_SCHEMA", "text", true], ["CHARACTER_SETS", "text", true]]
               | _rest
             ]
           } = first_binary |> :brotli.decode() |> elem(1) |> Jason.decode!()

    assert_receive {:query_stream, {:chunk, {:ok, second_binary}}}, 1000

    assert %{
             "columns" => ["database", "name"],
             "command" => "select",
             "num_rows" => 10,
             "rows" => [
               [["INFORMATION_SCHEMA", "text", true], ["character_sets", "text", true]]
               | _rest
             ]
           } = second_binary |> :brotli.decode() |> elem(1) |> Jason.decode!()

    assert_receive {:query_stream, :done}
  end

  test "streaming error" do
    organization = insert(:organization)
    user = insert(:user)
    organization_user = insert(:organization_user, organization: organization, user: user)

    credential =
      insert(:database_credential,
        default_credential: true,
        database:
          build(:database,
            organization: organization,
            permissions: [build(:object_permission, permission: :write, organization_user: organization_user)]
          )
      )

    query =
      insert(:query,
        user: user,
        organization: organization,
        credential: credential,
        query: "SELECT * FROM not_found ORDER BY version LIMIT 20;"
      )

    Phoenix.PubSub.subscribe(Devhub.PubSub, query.id)

    assert {:ok, {:stream, _task}, _query} = QueryDesk.run_query(query, stream?: true)

    assert_receive {:query_stream, {:chunk, {:ok, binary}, {:error, error_msg}}}, 1000

    assert error_msg == "relation \"not_found\" does not exist"

    assert %{"error" => ^error_msg} =
             binary |> :brotli.decode() |> elem(1) |> Jason.decode!()

    assert_receive {:query_stream, :done}
  end

  test "local - bad query" do
    organization = insert(:organization)
    user = insert(:user)
    organization_user = insert(:organization_user, organization: organization, user: user)

    credential =
      insert(:database_credential,
        default_credential: true,
        database:
          build(:database,
            organization: organization,
            permissions: [build(:object_permission, permission: :write, organization_user: organization_user)]
          )
      )

    query =
      insert(:query,
        user: user,
        organization: credential.database.organization,
        credential: credential,
        query: "SELECT * FROM not_found LIMIT 500;"
      )

    assert {:error, "relation \"not_found\" does not exist", query} = QueryDesk.run_query(query)

    assert %{
             failed: true,
             executed_at: executed_at
           } = query

    refute is_nil(executed_at)
  end

  test "local - bad query with multiple queries" do
    organization = insert(:organization)
    user = insert(:user)
    organization_user = insert(:organization_user, organization: organization, user: user)

    credential =
      insert(:database_credential,
        default_credential: true,
        database:
          build(:database,
            organization: organization,
            permissions: [build(:object_permission, permission: :write, organization_user: organization_user)]
          )
      )

    query =
      insert(:query,
        user: user,
        organization: credential.database.organization,
        credential: credential,
        query: """
        SELECT * FROM not_found LIMIT 500;
        UPDATE users SET updated_at = now();
        """
      )

    assert {:error, ["ERROR: relation \"not_found\" does not exist", "update 0"], query} = QueryDesk.run_query(query)

    assert %{
             failed: true,
             executed_at: executed_at
           } = query

    refute is_nil(executed_at)
  end

  test "not approved" do
    organization = insert(:organization)
    user = insert(:user)
    organization_user = insert(:organization_user, organization: organization, user: user)

    credential =
      insert(:database_credential,
        default_credential: true,
        reviews_required: 1,
        database:
          build(:database,
            organization: organization,
            slack_channel: "#general",
            permissions: [build(:object_permission, permission: :write, organization_user: organization_user)]
          )
      )

    query =
      insert(:query,
        user: user,
        organization: credential.database.organization,
        credential: credential,
        query: "SELECT * FROM schema_migrations LIMIT 500;"
      )

    assert {:error, :pending_approval, _query} = QueryDesk.run_query(query)
  end

  test "can run query with longer timeout" do
    organization = insert(:organization)
    user = insert(:user)
    organization_user = insert(:organization_user, organization: organization, user: user)

    credential =
      insert(:database_credential,
        default_credential: true,
        database:
          build(:database,
            organization: organization,
            permissions: [build(:object_permission, permission: :write, organization_user: organization_user)]
          )
      )

    query =
      insert(:query,
        user: user,
        organization: credential.database.organization,
        credential: credential,
        query: "SELECT * FROM schema_migrations ORDER BY version LIMIT 100;",
        timeout: 10
      )

    assert {:ok, result, _query} = QueryDesk.run_query(query)

    assert %{
             columns: ["version", "inserted_at"],
             rows: [[20_240_321_034_813, _name] | _rest]
           } = result
  end
end
