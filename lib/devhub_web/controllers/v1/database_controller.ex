defmodule DevhubWeb.V1.DatabaseController do
  use DevhubWeb, :controller

  alias Devhub.QueryDesk

  def show(conn, %{"id" => id}) do
    case QueryDesk.get_database(id: id, organization_id: conn.assigns.organization_id) do
      {:ok, database} ->
        json(conn, database)

      {:error, _error} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:"404")
    end
  end

  def create(conn, params) do
    params
    |> Map.put("organization_id", conn.assigns.organization_id)
    |> QueryDesk.create_database()
    |> case do
      {:ok, database} -> json(conn, database)
      {:error, changeset} -> error_response(conn, changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    params = Map.put(params, "organization_id", conn.assigns.organization_id)

    with {:ok, database} <- QueryDesk.get_database(id: id, organization_id: conn.assigns.organization_id),
         {:ok, database} <- QueryDesk.update_database(database, params) do
      json(conn, database)
    else
      {:error, :database_not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:"404")

      {:error, changeset} ->
        error_response(conn, changeset)
    end
  end

  def delete(conn, %{"api_id" => id}) do
    with {:ok, database} <- QueryDesk.get_database(api_id: id, organization_id: conn.assigns.organization_id),
         {:ok, database} <- QueryDesk.delete_database(database) do
      json(conn, database)
    else
      {:error, :database_not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:"404")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, database} <- QueryDesk.get_database(id: id, organization_id: conn.assigns.organization_id),
         {:ok, database} <- QueryDesk.delete_database(database) do
      json(conn, database)
    else
      {:error, :database_not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:"404")
    end
  end

  def setup(conn, params) do
    with {:ok, params} <- parse_setup_params(conn, params),
         {:ok, database} <-
           QueryDesk.get_database(api_id: params.api_id, organization_id: conn.assigns.organization_id),
         {:ok, database} <- QueryDesk.update_database(database, params) do
      json(conn, database)
    else
      {:error, :database_not_found} ->
        with {:ok, params} <- parse_setup_params(conn, params),
             {:ok, database} <- QueryDesk.create_database(params) do
          json(conn, database)
        else
          {:error, changeset} -> error_response(conn, changeset)
        end

      {:error, :invalid_params} ->
        error_response(conn, %Ecto.Changeset{})

      {:error, changeset} ->
        error_response(conn, changeset)
    end
  end

  defp error_response(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: DevhubWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  defp parse_setup_params(conn, params) do
    {:ok,
     %{
       organization_id: conn.assigns.organization_id,
       api_id: Map.fetch!(params, "id"),
       name: params["name"] || params["database"],
       adapter: params["adapter"],
       hostname: params["hostname"],
       port: params["port"],
       database: params["database"],
       group: params["group"],
       agent_id: params["agent_id"],
       ssl: params["ssl"] == "enabled",
       cacertfile: maybe_base64_decode(params["ssl_ca_cert"]),
       keyfile: maybe_base64_decode(params["ssl_key"]),
       certfile: maybe_base64_decode(params["ssl_cert"]),
       credentials: [
         %{
           username: params["username"],
           password: params["password"],
           reviews_required: params["reviews_required"] || 0,
           default_credential: true
         }
       ]
     }}
  rescue
    _error -> {:error, :invalid_params}
  end
end
