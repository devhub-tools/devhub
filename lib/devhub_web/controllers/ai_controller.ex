defmodule DevhubWeb.AIController do
  use DevhubWeb, :controller

  alias Devhub.Integrations.AI

  def complete_query(conn, params) do
    case AI.complete_query(conn.assigns.organization_user, params["database_id"], params["prefix"], params["suffix"]) do
      {:ok, prediction} ->
        json(conn, %{prediction: prediction})

      _error ->
        json(conn, %{error: "Failed to complete query"})
    end
  end
end
