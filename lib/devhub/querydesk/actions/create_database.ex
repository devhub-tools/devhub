defmodule Devhub.QueryDesk.Actions.CreateDatabase do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.Repo

  @callback create_database(map()) :: {:ok, Database.t()} | {:error, Ecto.Changeset.t()}
  def create_database(params) do
    params
    |> Database.changeset()
    |> Repo.insert()
  end
end
