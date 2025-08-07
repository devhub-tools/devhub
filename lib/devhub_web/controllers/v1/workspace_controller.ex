defmodule DevhubWeb.V1.WorkspaceController do
  use DevhubWeb, :controller

  alias Devhub.Integrations.GitHub
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Workspace

  def show(conn, %{"id" => id}) do
    case TerraDesk.get_workspace(id: id, organization_id: conn.assigns.organization_id) do
      {:ok, workspace} ->
        workspace = %{workspace | repository: workspace.repository.owner <> "/" <> workspace.repository.name}
        json(conn, workspace)

      {:error, _error} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:"404")
    end
  end

  def create(conn, params) do
    with [owner, name] <- String.split(params["repository"] || "", "/"),
         {:ok, repository} <-
           GitHub.get_repository(owner: owner, name: name, organization_id: conn.assigns.organization_id),
         {:ok, workspace} <-
           params
           |> Map.put("organization_id", conn.assigns.organization_id)
           |> Map.put("repository_id", repository.id)
           |> TerraDesk.create_workspace() do
      workspace = %{workspace | repository: repository.owner <> "/" <> repository.name}
      json(conn, workspace)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(conn, changeset)

      _error ->
        error_response(conn, :repository, "not found")
    end
  end

  def update(conn, %{"id" => id} = params) do
    with [owner, name] <- String.split(params["repository"] || "", "/"),
         {:ok, repository} <-
           GitHub.get_repository(owner: owner, name: name, organization_id: conn.assigns.organization_id),
         {:ok, workspace} <- TerraDesk.get_workspace(id: id, organization_id: conn.assigns.organization_id),
         params =
           params
           |> Map.put("organization_id", conn.assigns.organization_id)
           |> Map.put("repository_id", repository.id),
         {:ok, workspace} <- TerraDesk.insert_or_update_workspace(workspace, params) do
      workspace = %{workspace | repository: repository.owner <> "/" <> repository.name}
      json(conn, workspace)
    else
      {:error, :workspace_not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:"404")

      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(conn, changeset)

      _error ->
        error_response(conn, :repository, "not found")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, workspace} <- TerraDesk.get_workspace(id: id, organization_id: conn.assigns.organization_id),
         {:ok, workspace} <- TerraDesk.delete_workspace(workspace) do
      workspace = %{workspace | repository: workspace.repository.owner <> "/" <> workspace.repository.name}
      json(conn, workspace)
    else
      {:error, :workspace_not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:"404")
    end
  end

  defp error_response(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: DevhubWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  defp error_response(conn, field, error) do
    changeset = %Workspace{} |> Ecto.Changeset.change(%{}) |> Ecto.Changeset.add_error(field, error)
    error_response(conn, changeset)
  end
end
