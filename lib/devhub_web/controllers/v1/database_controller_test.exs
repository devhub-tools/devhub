defmodule DevhubWeb.V1.DatabaseControllerTest do
  use DevhubWeb.ConnCase, async: true

  @tag :unauthenticated
  test "GET /api/v1/querydesk/databases/:id", %{conn: conn, organization: organization} do
    {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "db update test", [:full_access])

    %{
      id: database_id,
      credentials: [
        %{id: first_cred_id, default_credential: true},
        %{id: second_cred_id}
      ]
    } =
      database =
      insert(:database,
        organization: organization,
        credentials: [
          build(:database_credential, username: "first", default_credential: true),
          build(:database_credential, username: "second")
        ]
      )

    assert %{
             "id" => ^database_id,
             "adapter" => "postgres",
             "database" => "devhub_test",
             "hostname" => "localhost",
             "name" => "My Database",
             "restrict_access" => false,
             "ssl" => false,
             "credentials" =>
               [
                 %{
                   "default_credential" => true,
                   "id" => ^first_cred_id,
                   "reviews_required" => 0,
                   "username" => "first"
                 },
                 %{
                   "default_credential" => false,
                   "id" => ^second_cred_id,
                   "reviews_required" => 0,
                   "username" => "second"
                 }
               ] = credentials,
             "group" => nil,
             "inserted_at" => _inserted_at,
             "slack_channel" => nil,
             "updated_at" => _updated_at
           } =
             database =
             conn
             |> put_req_header("x-api-key", key)
             |> get(~p"/api/v1/querydesk/databases/#{database.id}")
             |> json_response(200)

    # make sure only the expected keys are returned
    assert Map.keys(database) ==
             [
               "adapter",
               "agent_id",
               "api_id",
               "credentials",
               "database",
               "group",
               "hostname",
               "id",
               "inserted_at",
               "name",
               "port",
               "restrict_access",
               "slack_channel",
               "ssl",
               "updated_at"
             ]

    Enum.each(credentials, fn credential ->
      # make sure password is not returned
      assert Map.keys(credential) == ["default_credential", "hostname", "id", "reviews_required", "username"]
    end)

    assert %{"errors" => %{"detail" => "Not Found"}} =
             conn
             |> put_req_header("x-api-key", key)
             |> get(~p"/api/v1/querydesk/databases/not-found")
             |> json_response(404)
  end

  @tag :unauthenticated
  test "POST /api/v1/querydesk/databases", %{conn: conn, organization: organization} do
    {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "db update test", [:full_access])

    params = %{
      "adapter" => "postgres",
      "agent_id" => "",
      "credentials" => [
        %{
          "default_credential" => "false",
          "reviews_required" => "4",
          "username" => "first",
          "password" => "password"
        },
        %{
          "default_credential" => "true",
          "reviews_required" => "1",
          "username" => "second",
          "password" => "password"
        }
      ],
      "database" => "devhub_dev",
      "group" => "",
      "hostname" => "127.0.0.1",
      "name" => "Devhub",
      "restrict_access" => "true",
      "slack_channel" => "",
      "ssl" => "false"
    }

    assert %{
             "adapter" => "postgres",
             "database" => "devhub_dev",
             "hostname" => "127.0.0.1",
             "name" => "Devhub",
             "restrict_access" => true,
             "ssl" => false,
             "credentials" => [
               %{
                 "default_credential" => false,
                 "reviews_required" => 4,
                 "username" => "first"
               },
               %{
                 "default_credential" => true,
                 "reviews_required" => 1,
                 "username" => "second"
               }
             ],
             "group" => nil,
             "inserted_at" => _inserted_at,
             "slack_channel" => nil,
             "updated_at" => _updated_at
           } =
             conn
             |> put_req_header("x-api-key", key)
             |> post(~p"/api/v1/querydesk/databases", params)
             |> json_response(200)
  end

  @tag :unauthenticated
  test "PATCH /api/v1/querydesk/databases/:id", %{conn: conn, organization: organization} do
    {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "db update test", [:full_access])

    %{
      id: database_id,
      credentials: [
        %{id: first_cred_id, default_credential: true},
        # should be deleted
        %{id: _second_cred_id}
      ]
    } =
      database =
      insert(:database,
        organization: organization,
        credentials: [
          build(:database_credential, username: "first", default_credential: true),
          build(:database_credential, username: "second")
        ]
      )

    params = %{
      "adapter" => "postgres",
      "agent_id" => "",
      "credentials" => %{
        "0" => %{
          "default_credential" => "false",
          "id" => first_cred_id,
          "reviews_required" => "4",
          "username" => "first"
        },
        "1" => %{
          "default_credential" => "true",
          "reviews_required" => "1",
          "username" => "third",
          "password" => "password"
        }
      },
      "database" => "devhub_dev",
      "group" => "",
      "hostname" => "127.0.0.1",
      "name" => "Devhub",
      "restrict_access" => "true",
      "slack_channel" => "",
      "ssl" => "false"
    }

    assert %{
             "id" => ^database_id,
             "adapter" => "postgres",
             "database" => "devhub_dev",
             "hostname" => "127.0.0.1",
             "name" => "Devhub",
             "restrict_access" => true,
             "ssl" => false,
             "credentials" => [
               %{
                 "default_credential" => false,
                 "id" => ^first_cred_id,
                 "reviews_required" => 4,
                 "username" => "first"
               },
               %{
                 "default_credential" => true,
                 "reviews_required" => 1,
                 "username" => "third"
               }
             ],
             "group" => nil,
             "inserted_at" => _inserted_at,
             "slack_channel" => nil,
             "updated_at" => _updated_at
           } =
             conn
             |> put_req_header("x-api-key", key)
             |> patch(~p"/api/v1/querydesk/databases/#{database.id}", params)
             |> json_response(200)

    assert %{"errors" => %{"adapter" => ["is invalid"]}} =
             conn
             |> put_req_header("x-api-key", key)
             |> patch(~p"/api/v1/querydesk/databases/#{database.id}", %{"adapter" => "wrong"})
             |> json_response(422)

    assert %{"errors" => %{"detail" => "Not Found"}} =
             conn
             |> put_req_header("x-api-key", key)
             |> patch(~p"/api/v1/querydesk/databases/not-found", params)
             |> json_response(404)
  end

  describe "DELETE /api/v1/querydesk/databases/:id" do
    @tag :unauthenticated
    test "delete by id", %{conn: conn, organization: organization} do
      {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "db update test", [:full_access])

      %{id: database_id} =
        insert(:database,
          organization: organization,
          credentials: [
            build(:database_credential, username: "first", default_credential: true),
            build(:database_credential, username: "second")
          ]
        )

      assert %{"id" => ^database_id} =
               conn
               |> put_req_header("x-api-key", key)
               |> delete(~p"/api/v1/querydesk/databases/#{database_id}")
               |> json_response(200)

      assert %{"errors" => %{"detail" => "Not Found"}} =
               conn
               |> put_req_header("x-api-key", key)
               |> delete(~p"/api/v1/querydesk/databases/#{database_id}")
               |> json_response(404)
    end

    @tag :unauthenticated
    test "delete by api id", %{conn: conn, organization: organization} do
      {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "db update test", [:querydesk_limited])

      %{id: database_id} = database = insert(:database, organization: organization, api_id: "pr-1")

      assert %{"id" => ^database_id} =
               conn
               |> put_req_header("x-api-key", key)
               |> delete(~p"/api/v1/querydesk/databases/remove/#{database.api_id}")
               |> json_response(200)
    end
  end

  describe "PUT /api/v1/querydesk/databases/setup" do
    @tag :unauthenticated
    test "success", %{conn: conn, organization: organization} do
      %{id: agent_id} = insert(:agent, organization: organization)
      {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "db update test", [:querydesk_limited])

      assert %{
               "id" => id,
               "api_id" => "pr-1",
               "adapter" => "postgres",
               "credentials" => [
                 %{
                   "default_credential" => true,
                   "reviews_required" => 0,
                   "username" => "postgres"
                 }
               ],
               "database" => "query_desk_test",
               "group" => nil,
               "hostname" => "localhost",
               "name" => "query_desk_test",
               "restrict_access" => false,
               "slack_channel" => nil,
               "ssl" => false,
               "agent_id" => ^agent_id
             } =
               conn
               |> put_req_header("x-api-key", key)
               |> put("/api/v1/querydesk/databases/setup", %{
                 "id" => "pr-1",
                 "username" => "postgres",
                 "password" => "postgres",
                 "adapter" => "postgres",
                 "hostname" => "localhost",
                 "database" => "query_desk_test",
                 "agent_id" => agent_id
               })
               |> json_response(200)

      assert %{
               "id" => ^id,
               "api_id" => "pr-1"
             } =
               conn
               |> put_req_header("x-api-key", key)
               |> put("/api/v1/querydesk/databases/setup", %{
                 "id" => "pr-1",
                 "username" => "postgres",
                 "password" => "postgres2",
                 "adapter" => "postgres",
                 "hostname" => "localhost",
                 "database" => "query_desk_test"
               })
               |> json_response(200)
    end

    @tag :unauthenticated
    test "with ssl", %{conn: conn, organization: organization} do
      {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "db update test", [:full_access])

      assert %{
               "ssl" => true
             } =
               conn
               |> put_req_header("x-api-key", key)
               |> put("/api/v1/querydesk/databases/setup", %{
                 "id" => "pr-3",
                 "username" => "postgres",
                 "password" => "postgres",
                 "adapter" => "postgres",
                 "hostname" => "localhost",
                 "database" => "query_desk_test",
                 "ssl" => "enabled",
                 "ssl_ca_cert" => Base.encode64("cacert"),
                 "ssl_key" => Base.encode64("key"),
                 "ssl_cert" => Base.encode64("cert")
               })
               |> json_response(200)
    end

    @tag :unauthenticated
    test "invalid ssl", %{conn: conn, organization: organization} do
      {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "db update test", [:full_access])

      assert conn
             |> put_req_header("x-api-key", key)
             |> put("/api/v1/querydesk/databases/setup", %{
               "id" => "pr-3",
               "username" => "postgres",
               "password" => "postgres",
               "adapter" => "postgres",
               "hostname" => "localhost",
               "database" => "query_desk_test",
               "ssl" => "enabled",
               "ssl_ca_cert" => "cacert",
               "ssl_key" => "key",
               "ssl_cert" => "cert"
             })
             |> json_response(422)
    end

    @tag :unauthenticated
    test "missing fields", %{conn: conn, organization: organization} do
      {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "db update test", [:full_access])

      assert conn
             |> put_req_header("x-api-key", key)
             |> put("/api/v1/querydesk/databases/setup", %{
               "id" => "pr-3"
             })
             |> json_response(422)
    end
  end
end
