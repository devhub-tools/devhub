defmodule DevhubWeb.V1.UserControllerTest do
  use DevhubWeb.ConnCase, async: true

  setup %{organization: organization} do
    stub(Devhub.ApiKeys, :verify, fn _id -> {:ok, build(:api_key, organization: organization)} end)
    :ok
  end

  @tag :unauthenticated
  test "GET /api/v1/users/:id", %{conn: conn, organization: organization} do
    user = insert(:user)
    %{id: organization_user_id} = insert(:organization_user, user: user, organization: organization)

    assert %{
             "id" => organization_user_id,
             "email" => user.email,
             "name" => user.name
           } ==
             conn
             |> put_req_header("x-api-key", "dh_123")
             |> get(~p"/api/v1/users/lookup?email=#{user.email}")
             |> json_response(200)
  end
end
