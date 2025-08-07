defmodule DevhubWeb.V1.DashboardController do
  use DevhubWeb, :controller

  alias Devhub.Dashboards

  def show(conn, %{"id" => id}) do
    case Dashboards.get_dashboard(id: id, organization_id: conn.assigns.organization_id) do
      {:ok, dashboard} ->
        json(conn, dashboard)

      {:error, _error} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:not_found)
    end
  end

  def create(conn, params) do
    params = Map.put(params, "organization_id", conn.assigns.organization_id)

    case Dashboards.create_dashboard(params) do
      {:ok, dashboard} ->
        json(conn, dashboard)

      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(conn, changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, dashboard} <- Dashboards.get_dashboard(id: id, organization_id: conn.assigns.organization_id),
         {:ok, dashboard} <- Dashboards.update_dashboard(dashboard, params) do
      json(conn, dashboard)
    else
      {:error, :dashboard_not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:not_found)

      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, dashboard} <- Dashboards.get_dashboard(id: id, organization_id: conn.assigns.organization_id),
         {:ok, dashboard} <- Dashboards.delete_dashboard(dashboard) do
      json(conn, dashboard)
    else
      {:error, :dashboard_not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:not_found)
    end
  end

  defp error_response(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: DevhubWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end
end
