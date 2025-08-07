defmodule Devhub.QueryDesk.Utils.TerminateConnections do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.QueryDesk.Cache
  alias Devhub.QueryDesk.RepoRegistry
  alias Devhub.QueryDesk.RepoSupervisor
  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.QueryDesk.Schemas.DatabaseCredential
  alias Devhub.Repo

  @callback terminate_connections(Database.t()) :: :ok
  def terminate_connections(database) do
    query =
      from c in DatabaseCredential,
        where: c.database_id == ^database.id,
        select: c.id

    credential_ids = Repo.all(query)

    Enum.each(credential_ids, fn id ->
      Cache.delete("schema-#{id}")
    end)

    if is_nil(database.agent_id) do
      do_terminate_connections(credential_ids)
    else
      DevhubWeb.AgentConnection.send_command(database.agent_id, {__MODULE__, :do_terminate_connections, [credential_ids]})
    end

    :ok
  end

  def do_terminate_connections(credential_ids) do
    Enum.each(credential_ids, fn id ->
      with [{pid, _value}] <- Registry.lookup(RepoRegistry, id) do
        DynamicSupervisor.terminate_child(RepoSupervisor, pid)
      end
    end)
  end
end
