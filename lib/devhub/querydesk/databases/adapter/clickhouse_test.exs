defmodule Devhub.QueryDesk.Databases.Adapter.ClickHouseTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk.Databases.Adapter.ClickHouse
  alias Devhub.QueryDesk.Schemas.DatabaseColumn

  describe "get_schema/3" do
    test "success" do
      organization = insert(:organization)

      database =
        insert(:database,
          organization: organization,
          adapter: :clickhouse,
          database: "system",
          default_credential:
            build(:database_credential,
              default_credential: true,
              username: "default",
              password: "clickhouse"
            )
        )

      user = insert(:user)

      assert [%DatabaseColumn{table: "aggregate_function_combinators"} | _rest] =
               ClickHouse.get_schema(database, user.id, [])
    end
  end
end
