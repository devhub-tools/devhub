defmodule DevhubWeb.V1.WorkflowController do
  use DevhubWeb, :controller

  alias Devhub.Integrations.Linear
  alias Devhub.Workflows

  def run(conn, params) do
    with {:ok, workflow} <- Workflows.get_workflow(id: params["id"], organization_id: conn.assigns.organization_id),
         {:ok, _run} <- Workflows.run_workflow(workflow, params) do
      conn |> put_status(201) |> text("workflow started")
    else
      {:error, :workflow_not_found} -> conn |> put_status(404) |> text("not found")
      {:error, :invalid_input} -> conn |> put_status(400) |> text("invalid input")
    end
  end

  def show(conn, %{"id" => id}) do
    case Workflows.get_workflow(id: id, organization_id: conn.assigns.organization_id) do
      {:ok, workflow} ->
        json(conn, workflow)

      {:error, _error} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:not_found)
    end
  end

  def create(conn, params) do
    trigger_linear_label_id = maybe_lookup_trigger_linear_label_id(conn, params)

    params =
      params
      |> Map.put("organization_id", conn.assigns.organization_id)
      |> Map.put("trigger_linear_label_id", trigger_linear_label_id)

    case Workflows.create_workflow(params) do
      {:ok, workflow} ->
        workflow = Devhub.Repo.preload(workflow, [:trigger_linear_label, steps: :permissions])
        json(conn, workflow)

      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(conn, changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    trigger_linear_label_id = maybe_lookup_trigger_linear_label_id(conn, params)

    params =
      params
      |> Map.put("organization_id", conn.assigns.organization_id)
      |> Map.put("trigger_linear_label_id", trigger_linear_label_id)

    with {:ok, workflow} <- Workflows.get_workflow(id: id, organization_id: conn.assigns.organization_id),
         {:ok, workflow} <- Workflows.update_workflow(workflow, params) do
      json(conn, workflow)
    else
      {:error, :workflow_not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:not_found)

      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(conn, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, workflow} <- Workflows.get_workflow(id: id, organization_id: conn.assigns.organization_id),
         {:ok, workflow} <- Workflows.delete_workflow(workflow) do
      json(conn, workflow)
    else
      {:error, :workflow_not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: DevhubWeb.ErrorJSON)
        |> render(:not_found)
    end
  end

  defp maybe_lookup_trigger_linear_label_id(conn, params) do
    with name when is_binary(name) <- params["trigger_linear_label"]["name"],
         {:ok, label} <- Linear.get_label(organization_id: conn.assigns.organization_id, name: name) do
      label.id
    else
      _not_found -> nil
    end
  end

  defp error_response(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: DevhubWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end
end
