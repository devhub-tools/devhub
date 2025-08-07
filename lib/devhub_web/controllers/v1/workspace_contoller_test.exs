defmodule DevhubWeb.V1.WorkspaceControllerTest do
  use DevhubWeb.ConnCase, async: true

  @tag :unauthenticated
  test "GET /api/v1/terradesk/workspaces/:id", %{conn: conn, organization: organization} do
    {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "workspace controller test", [:full_access])

    %{id: workspace_id} =
      workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        workload_identity: %{
          organization: organization,
          enabled: true,
          provider: "devhub",
          service_account_email: "devhub@google.com"
        },
        env_vars: [build(:terradesk_env_var, name: "ENV_VAR_NAME", value: "ENV_VAR_VALUE")],
        secrets: [build(:terradesk_secret, name: "API_KEY", value: "api-key")]
      )

    assert %{
             "id" => ^workspace_id,
             "inserted_at" => _inserted_at,
             "name" => "server-config",
             "updated_at" => _updated_at,
             "agent_id" => nil,
             "cpu_requests" => "100m",
             "docker_image" => "hashicorp/terraform:1.9",
             "env_vars" => [
               %{"id" => _env_var_id, "name" => "ENV_VAR_NAME", "value" => "ENV_VAR_VALUE"}
             ],
             "init_args" => nil,
             "memory_requests" => "512M",
             "path" => "terraform",
             "repository" => "devhub-tools/devhub",
             "required_approvals" => 0,
             "run_plans_automatically" => false,
             "secrets" => [%{"id" => _secret_id, "name" => "API_KEY"} = secret],
             "workload_identity" => %{
               "enabled" => true,
               "provider" => "devhub",
               "service_account_email" => "devhub@google.com"
             }
           } =
             response =
             conn
             |> put_req_header("x-api-key", key)
             |> get(~p"/api/v1/terradesk/workspaces/#{workspace.id}")
             |> json_response(200)

    # make sure only the expected keys are returned
    assert Map.keys(response) ==
             [
               "agent_id",
               "cpu_requests",
               "docker_image",
               "env_vars",
               "id",
               "init_args",
               "inserted_at",
               "memory_requests",
               "name",
               "path",
               "repository",
               "required_approvals",
               "run_plans_automatically",
               "secrets",
               "updated_at",
               "workload_identity"
             ]

    # make sure secret value isn't returned
    assert Map.keys(secret) == ["id", "name"]

    assert %{"errors" => %{"detail" => "Not Found"}} =
             conn
             |> put_req_header("x-api-key", key)
             |> get(~p"/api/v1/terradesk/workspaces/not-found")
             |> json_response(404)
  end

  @tag :unauthenticated
  test "POST /api/v1/terradesk/workspaces", %{conn: conn, organization: organization} do
    {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "workspace controller test", [:full_access])
    insert(:repository, organization: organization)

    params = %{
      "name" => "server-config",
      "agent_id" => nil,
      "cpu_requests" => "100m",
      "docker_image" => "hashicorp/terraform:1.9",
      "env_vars" => [%{"name" => "ENV_VAR_NAME", "value" => "ENV_VAR_VALUE"}],
      "init_args" => nil,
      "memory_requests" => "512M",
      "path" => "terraform",
      "repository" => "devhub-tools/devhub",
      "required_approvals" => 0,
      "run_plans_automatically" => false,
      "secrets" => [%{"name" => "API_KEY", "value" => "api-key"}],
      "workload_identity" => %{
        "enabled" => true,
        "provider" => "devhub",
        "service_account_email" => "devhub@google.com"
      }
    }

    assert %{
             "inserted_at" => _inserted_at,
             "name" => "server-config",
             "updated_at" => _updated_at,
             "agent_id" => nil,
             "cpu_requests" => "100m",
             "docker_image" => "hashicorp/terraform:1.9",
             "env_vars" => [
               %{"id" => _env_var_id, "name" => "ENV_VAR_NAME", "value" => "ENV_VAR_VALUE"}
             ],
             "init_args" => nil,
             "memory_requests" => "512M",
             "path" => "terraform",
             "repository" => "devhub-tools/devhub",
             "required_approvals" => 0,
             "run_plans_automatically" => false,
             "secrets" => [%{"id" => _secret_id, "name" => "API_KEY"}],
             "workload_identity" => %{
               "enabled" => true,
               "provider" => "devhub",
               "service_account_email" => "devhub@google.com"
             }
           } =
             conn
             |> put_req_header("x-api-key", key)
             |> post(~p"/api/v1/terradesk/workspaces", params)
             |> json_response(200)
  end

  @tag :unauthenticated
  test "PATCH /api/v1/terradesk/workspaces/:id", %{conn: conn, organization: organization} do
    {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "workspace controller test", [:full_access])

    %{id: workspace_id, env_vars: [%{id: env_var_id}]} =
      workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        workload_identity: %{
          organization: organization,
          enabled: true,
          provider: "devhub",
          service_account_email: "devhub@google.com"
        },
        env_vars: [build(:terradesk_env_var, name: "ENV_VAR_NAME", value: "ENV_VAR_VALUE")],
        secrets: [build(:terradesk_secret, name: "API_KEY", value: "api-key")]
      )

    params = %{
      "repository" => "devhub-tools/devhub",
      "env_vars" => [
        %{
          "id" => env_var_id,
          "name" => "ENV_VAR_NEW",
          "value" => "ENV_VAR_VALUE"
        },
        %{
          "name" => "OTHER",
          "value" => "other"
        }
      ]
    }

    assert %{
             "id" => ^workspace_id,
             "env_vars" => [
               %{
                 "id" => ^env_var_id,
                 "name" => "ENV_VAR_NEW",
                 "value" => "ENV_VAR_VALUE"
               },
               %{
                 "name" => "OTHER",
                 "value" => "other"
               }
             ]
           } =
             conn
             |> put_req_header("x-api-key", key)
             |> patch(~p"/api/v1/terradesk/workspaces/#{workspace.id}", params)
             |> json_response(200)

    assert %{"errors" => %{"repository" => ["not found"]}} =
             conn
             |> put_req_header("x-api-key", key)
             |> patch(~p"/api/v1/terradesk/workspaces/#{workspace.id}", %{"repository" => "devhub-tools/not-found"})
             |> json_response(422)

    assert %{"errors" => %{"detail" => "Not Found"}} =
             conn
             |> put_req_header("x-api-key", key)
             |> patch(~p"/api/v1/terradesk/workspaces/not-found", params)
             |> json_response(404)
  end

  describe "DELETE /api/v1/terradesk/workspaces/:id" do
    @tag :unauthenticated
    test "delete by id", %{conn: conn, organization: organization} do
      {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "workspace controller test", [:full_access])

      %{id: workspace_id} =
        insert(:workspace,
          organization: organization,
          repository: build(:repository, organization: organization),
          workload_identity: %{
            organization: organization,
            enabled: true,
            provider: "devhub",
            service_account_email: "devhub@google.com"
          },
          env_vars: [build(:terradesk_env_var, name: "ENV_VAR_NAME", value: "ENV_VAR_VALUE")],
          secrets: [build(:terradesk_secret, name: "API_KEY", value: "api-key")]
        )

      assert %{"id" => ^workspace_id} =
               conn
               |> put_req_header("x-api-key", key)
               |> delete(~p"/api/v1/terradesk/workspaces/#{workspace_id}")
               |> json_response(200)

      assert %{"errors" => %{"detail" => "Not Found"}} =
               conn
               |> put_req_header("x-api-key", key)
               |> delete(~p"/api/v1/terradesk/workspaces/#{workspace_id}")
               |> json_response(404)
    end
  end

  @tag :unauthenticated
  test "create handles errors", %{conn: conn, organization: organization} do
    {:ok, _api_key, key} = Devhub.ApiKeys.create(organization, "workspace controller test", [:full_access])
    insert(:repository, organization: organization)

    params = %{
      "agent_id" => "ag_123"
    }

    assert %{"errors" => %{"repository" => ["not found"]}} =
             conn
             |> put_req_header("x-api-key", key)
             |> post(~p"/api/v1/terradesk/workspaces", params)
             |> json_response(422)

    params = %{
      "repository" => "devhub-tools/devhub",
      "agent_id" => "ag_123"
    }

    assert %{"errors" => %{"name" => ["can't be blank"]}} =
             conn
             |> put_req_header("x-api-key", key)
             |> post(~p"/api/v1/terradesk/workspaces", params)
             |> json_response(422)

    params = %{
      "name" => "server-config",
      "repository" => "devhub-tools/devhub",
      "agent_id" => "ag_123"
    }

    assert %{"errors" => %{"agent_id" => ["does not exist"]}} =
             conn
             |> put_req_header("x-api-key", key)
             |> post(~p"/api/v1/terradesk/workspaces", params)
             |> json_response(422)
  end
end
