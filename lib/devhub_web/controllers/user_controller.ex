defmodule DevhubWeb.V1.UserController do
  use DevhubWeb, :controller

  alias Devhub.Users

  def show(conn, params) do
    organization_id = conn.assigns.organization_id

    by =
      case params do
        %{"name" => name} when is_binary(name) -> [name: name]
        %{"email" => email} when is_binary(email) -> [email: email]
      end

    case Users.get_by(by) do
      {:ok, %{organization_users: [%{organization_id: ^organization_id} = organization_user]} = user} ->
        json(conn, %{id: organization_user.id, email: user.email, name: user.name})

      _not_found_or_no_match ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:not_found)
    end
  end
end
