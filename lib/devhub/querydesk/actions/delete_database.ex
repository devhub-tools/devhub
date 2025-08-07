defmodule Devhub.QueryDesk.Actions.DeleteDatabase do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.QueryDesk.Utils.TerminateConnections
  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.QueryDesk.Schemas.DatabaseColumn
  alias Devhub.Repo

  @callback delete_database(Database.t()) :: {:ok, Database.t()} | {:error, Ecto.Changeset.t()}
  def delete_database(database) do
    :ok = terminate_connections(database)
    Repo.delete_all(from c in DatabaseColumn, where: c.database_id == ^database.id)
    Repo.delete(database, allow_stale: true)
  end
end
