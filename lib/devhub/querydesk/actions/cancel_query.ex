defmodule Devhub.QueryDesk.Actions.CancelQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.Query

  @callback cancel_query(query :: Query.t(), query_task :: Task.t()) :: :ok
  def cancel_query(query, query_task) do
    query = Devhub.Repo.preload(query, credential: :database)

    if is_nil(query.credential.database.agent_id) or Application.get_env(:devhub, :agent) do
      do_cancel_query(query_task)
    else
      DevhubWeb.AgentConnection.send_command(
        query.credential.database.agent_id,
        {__MODULE__, :do_cancel_query, [query_task]}
      )
    end
  end

  def do_cancel_query(query_task) do
    Process.exit(query_task.pid, :kill)
  end
end
