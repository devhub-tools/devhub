defmodule Devhub.Coverbot.Actions.CreateCoverage do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Coverbot.Coverage
  alias Devhub.Repo

  @callback create_coverage(map()) :: {:ok, Coverage.t()} | {:error, Ecto.Changeset.t()}
  def create_coverage(attrs) do
    attrs
    |> Coverage.changeset()
    |> Repo.insert()
  end
end
