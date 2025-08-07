defmodule Devhub.Workflows.Actions.CancelRun do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Run

  @callback cancel_run(Run.t()) :: {:ok, Run.t()} | {:error, Ecto.Changeset.t()}
  def cancel_run(run) do
    run
    |> Run.changeset(%{status: :canceled})
    |> Repo.update()
  end
end
