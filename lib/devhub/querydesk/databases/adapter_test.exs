defmodule Devhub.QueryDesk.Databases.AdapterTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Databases.Adapter
  alias Devhub.QueryDesk.Schemas.Query

  describe "get_table_data/4" do
    test "postgres" do
      user = build(:user)
      database = build(:database, adapter: :postgres, default_credential: build(:database_credential))

      stub(QueryDesk, :create_query, fn params ->
        {:ok, build(:query, params)}
      end)

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users", [])

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" ORDER BY "inserted_at" ASC LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users", order_by: %{field: "inserted_at", direction: :asc})

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" ORDER BY "inserted_at" DESC LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users", order_by: %{field: "inserted_at", direction: :desc})

      assert {:ok,
              %Query{
                query:
                  ~s(SELECT * FROM "users" WHERE "inserted_at" > '2021-01-01' AND "updated_at" < '2021-01-01' AND "archived_at" <= '2021-01-01' AND "deleted_at" >= '2021-01-01' LIMIT 500)
              }} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [
                   %{column: "inserted_at", operator: :greater_than, value: "2021-01-01"},
                   %{column: "updated_at", operator: :less_than, value: "2021-01-01"},
                   %{column: "archived_at", operator: :less_than_or_equal, value: "2021-01-01"},
                   %{column: "deleted_at", operator: :greater_than_or_equal, value: "2021-01-01"}
                 ]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" WHERE "inserted_at" IS NULL LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users", filters: [%{column: "inserted_at", operator: :is_null}])

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" WHERE "inserted_at" IS NOT NULL LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "inserted_at", operator: :is_not_null}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" WHERE "id" = '123' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :equals, value: "123"}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" WHERE "id" != '123' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :not_equals, value: "123"}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" WHERE "id"::text ILIKE '%123%' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :like, value: "%123%"}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" WHERE "id"::text ILIKE '%123%' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :contains, value: "123"}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM "users" WHERE "id"::text NOT ILIKE '%123%' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :does_not_contain, value: "123"}]
               )
    end

    test "mysql" do
      user = build(:user)
      database = build(:database, adapter: :mysql, default_credential: build(:database_credential))

      stub(QueryDesk, :create_query, fn params ->
        {:ok, build(:query, params)}
      end)

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users", [])

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` ORDER BY `inserted_at` ASC LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users", order_by: %{field: "inserted_at", direction: :asc})

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` ORDER BY `inserted_at` DESC LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users", order_by: %{field: "inserted_at", direction: :desc})

      assert {:ok,
              %Query{
                query:
                  ~s(SELECT * FROM `users` WHERE `inserted_at` > '2021-01-01' AND `updated_at` < '2021-01-01' AND `archived_at` <= '2021-01-01' AND `deleted_at` >= '2021-01-01' LIMIT 500)
              }} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [
                   %{column: "inserted_at", operator: :greater_than, value: "2021-01-01"},
                   %{column: "updated_at", operator: :less_than, value: "2021-01-01"},
                   %{column: "archived_at", operator: :less_than_or_equal, value: "2021-01-01"},
                   %{column: "deleted_at", operator: :greater_than_or_equal, value: "2021-01-01"}
                 ]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` WHERE `inserted_at` IS NULL LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users", filters: [%{column: "inserted_at", operator: :is_null}])

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` WHERE `inserted_at` IS NOT NULL LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "inserted_at", operator: :is_not_null}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` WHERE `id` = '123' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :equals, value: "123"}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` WHERE `id` != '123' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :not_equals, value: "123"}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` WHERE `id` LIKE '%123%' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :like, value: "%123%"}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` WHERE `id` LIKE '%123%' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :contains, value: "123"}]
               )

      assert {:ok, %Query{query: ~s(SELECT * FROM `users` WHERE `id` NOT LIKE '%123%' LIMIT 500)}} =
               Adapter.get_table_data(database, user.id, "users",
                 filters: [%{column: "id", operator: :does_not_contain, value: "123"}]
               )
    end
  end
end
