defmodule Devhub.QueryDesk.Actions.TestConnectionTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  describe "postgres" do
    test "success" do
      %{credentials: [%{id: credential_id}]} =
        database =
        insert(:database,
          organization: build(:organization),
          hostname: "localhost",
          adapter: :postgres,
          database: "postgres",
          credentials: [build(:database_credential, username: "postgres", password: "postgres")]
        )

      assert :ok = QueryDesk.test_connection(database, credential_id)
    end

    test "bad creds" do
      %{credentials: [%{id: credential_id}]} =
        database =
        insert(:database,
          organization: build(:organization),
          hostname: "localhost",
          adapter: :postgres,
          database: "postgres",
          credentials: [build(:database_credential, username: "postgres", password: "password")]
        )

      assert {:error, "password authentication failed for user \"postgres\""} =
               QueryDesk.test_connection(database, credential_id)
    end

    test "bad host" do
      %{credentials: [%{id: credential_id}]} =
        database =
        insert(:database,
          organization: build(:organization),
          hostname: "local",
          adapter: :postgres,
          database: "postgres",
          credentials: [build(:database_credential, username: "postgres", password: "postgres")]
        )

      assert {:error, "tcp connect (local:5432): non-existing domain - :nxdomain"} =
               QueryDesk.test_connection(database, credential_id)
    end
  end

  describe "mysql" do
    test "success" do
      %{credentials: [%{id: credential_id}]} =
        database =
        insert(:database,
          organization: build(:organization),
          hostname: "localhost",
          adapter: :mysql,
          database: "information_schema",
          credentials: [build(:database_credential, username: "root", password: "root")]
        )

      assert :ok = QueryDesk.test_connection(database, credential_id)
    end

    test "bad creds" do
      %{credentials: [%{id: credential_id}]} =
        database =
        insert(:database,
          organization: build(:organization),
          hostname: "localhost",
          adapter: :mysql,
          database: "information_schema",
          credentials: [build(:database_credential, username: "root", password: "password")]
        )

      assert {:error, error} =
               QueryDesk.test_connection(database, credential_id)

      assert error =~ "Access denied for user 'root'@'"
    end

    test "bad host" do
      %{credentials: [%{id: credential_id}]} =
        database =
        insert(:database,
          organization: build(:organization),
          hostname: "local",
          adapter: :mysql,
          database: "information_schema",
          credentials: [build(:database_credential, username: "root", password: "root")]
        )

      assert {:error, "(local:3306) non-existing domain - :nxdomain"} =
               QueryDesk.test_connection(database, credential_id)
    end
  end

  describe "clickhouse" do
    test "success" do
      %{credentials: [%{id: credential_id}]} =
        database =
        insert(:database,
          organization: build(:organization),
          hostname: "localhost",
          adapter: :clickhouse,
          database: "system",
          credentials: [build(:database_credential, username: "default", password: "clickhouse")]
        )

      assert :ok = QueryDesk.test_connection(database, credential_id)
    end

    test "bad creds" do
      %{credentials: [%{id: credential_id}]} =
        database =
        insert(:database,
          organization: build(:organization),
          hostname: "localhost",
          adapter: :clickhouse,
          database: "information_schema",
          credentials: [build(:database_credential, username: "root", password: "password")]
        )

      assert {:error, error} =
               QueryDesk.test_connection(database, credential_id)

      assert error =~
               "root: Authentication failed: password is incorrect, or there is no user with such name. (AUTHENTICATION_FAILED)"
    end

    test "bad host" do
      %{credentials: [%{id: credential_id}]} =
        database =
        insert(:database,
          organization: build(:organization),
          hostname: "local",
          adapter: :clickhouse,
          database: "information_schema",
          credentials: [build(:database_credential, username: "root", password: "root")]
        )

      assert {:error, :nxdomain} =
               QueryDesk.test_connection(database, credential_id)
    end
  end
end
