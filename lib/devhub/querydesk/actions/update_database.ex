defmodule Devhub.QueryDesk.Actions.UpdateDatabase do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.QueryDesk.Utils.TerminateConnections
  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.QueryDesk.Schemas.DatabaseCredential
  alias Devhub.Repo

  @callback update_database(Database.t(), map()) ::
              {:ok, Database.t()} | {:error, Ecto.Changeset.t()}
  def update_database(database, params) do
    # we want to clear all existing connections before changing credentials
    # for example we need to do this first because credentials could be deleted
    :ok = terminate_connections(database)

    Repo.transaction(fn ->
      maybe_clear_default_credential(database, params)

      database
      |> Database.changeset(params)
      |> Repo.update(allow_stale: true)
      |> case do
        {:ok, database} ->
          database

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp maybe_clear_default_credential(database, params) do
    credentials = params["credentials"] || params[:credentials]

    if not is_nil(credentials) do
      default_credential =
        credentials
        |> Enum.map(fn
          {_index, credential} -> credential
          credential -> credential
        end)
        |> Enum.find(fn
          %{"id" => _id, "default_credential" => default} -> default in [true, "true"]
          _not_default -> false
        end)

      query =
        case default_credential do
          %{"id" => id} ->
            from c in DatabaseCredential, where: c.database_id == ^database.id and c.id != ^id

          _empty ->
            from c in DatabaseCredential, where: c.database_id == ^database.id
        end

      Repo.update_all(query, set: [default_credential: false])
    end
  end
end
