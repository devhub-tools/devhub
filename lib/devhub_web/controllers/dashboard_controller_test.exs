defmodule DevhubWeb.V1.DashboardControllerTest do
  use DevhubWeb.ConnCase, async: true

  alias Devhub.Dashboards.Schemas.Dashboard.QueryPanel

  setup %{organization: organization} do
    stub(Devhub.ApiKeys, :verify, fn _id -> {:ok, build(:api_key, organization: organization)} end)
    :ok
  end

  test "GET /api/v1/dashboards/:id", %{conn: conn, organization: organization} do
    %{id: credential_id} = insert(:database_credential, database: build(:database, organization: organization))

    %{id: dashboard_id, panels: [%{id: panel_id, inputs: []}, %{id: panel_2_id, inputs: [_input]}]} =
      :dashboard
      |> build(
        organization: organization,
        panels: [
          %{title: "Data view", details: %QueryPanel{query: "SELECT * FROM users", credential_id: credential_id}},
          %{
            title: "Data view with input",
            inputs: [%{key: "user_id", description: "the user id"}],
            details: %QueryPanel{
              query: "SELECT * FROM users WHERE id = '${user_id}'",
              credential_id: credential_id
            }
          }
        ]
      )
      |> Devhub.Repo.insert!()

    assert %{
             "id" => ^dashboard_id,
             "panels" => [
               %{
                 "id" => ^panel_id,
                 "inputs" => [],
                 "details" => %{
                   "__type__" => "query",
                   "query" => "SELECT * FROM users",
                   "credential_id" => ^credential_id
                 }
               },
               %{
                 "id" => ^panel_2_id,
                 "inputs" => [
                   %{"description" => "the user id", "key" => "user_id"}
                 ],
                 "details" => %{
                   "__type__" => "query",
                   "query" => "SELECT * FROM users WHERE id = '${user_id}'",
                   "credential_id" => ^credential_id
                 }
               }
             ]
           } =
             conn
             |> put_req_header("x-api-key", "dh_123")
             |> get(~p"/api/v1/dashboards/#{dashboard_id}")
             |> json_response(200)
  end

  @tag :unauthenticated
  test "POST /api/v1/dashboards", %{conn: conn, organization: organization} do
    %{id: credential_id} = insert(:database_credential, database: build(:database, organization: organization))

    input = %{
      "name" => "My dashboard",
      "restricted_access" => false,
      "panels" => [
        %{
          "title" => "My panel",
          "inputs" => nil,
          "details" => %{
            "__type__" => "query",
            "query" => "SELECT * FROM users",
            "credential_id" => credential_id
          }
        }
      ]
    }

    assert %{
             "name" => "My dashboard",
             "panels" => [
               %{
                 "title" => "My panel",
                 "details" => %{
                   "__type__" => "query",
                   "query" => "SELECT * FROM users",
                   "credential_id" => ^credential_id
                 }
               }
             ]
           } =
             conn
             |> put_req_header("x-api-key", "dh_123")
             |> post(~p"/api/v1/dashboards", input)
             |> json_response(200)
  end

  @tag :unauthenticated
  test "PATCH /api/v1/dashboards/:id", %{conn: conn, organization: organization} do
    %{id: dashboard_id} = insert(:dashboard, organization: organization)
    %{id: credential_id} = insert(:database_credential, database: build(:database, organization: organization))

    input = %{
      "name" => "My dashboard",
      "panels" => [
        %{
          "title" => "My panel",
          "details" => %{
            "__type__" => "query",
            "query" => "SELECT * FROM users",
            "credential_id" => credential_id
          }
        }
      ]
    }

    assert %{
             "id" => ^dashboard_id,
             "name" => "My dashboard",
             "panels" => [
               %{
                 "title" => "My panel",
                 "details" => %{
                   "__type__" => "query",
                   "query" => "SELECT * FROM users",
                   "credential_id" => ^credential_id
                 }
               }
             ]
           } =
             conn
             |> put_req_header("x-api-key", "dh_123")
             |> patch(~p"/api/v1/dashboards/#{dashboard_id}", input)
             |> json_response(200)
  end

  @tag :unauthenticated
  test "DELETE /api/v1/dashboards/:id", %{conn: conn, organization: organization} do
    %{id: dashboard_id} = insert(:dashboard, organization: organization)

    conn
    |> put_req_header("x-api-key", "dh_123")
    |> delete(~p"/api/v1/dashboards/#{dashboard_id}")
    |> json_response(200)

    refute Devhub.Repo.get(Devhub.Dashboards.Schemas.Dashboard, dashboard_id)
  end
end
