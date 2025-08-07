defmodule Devhub.Workflows.Actions.GetRun do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Run

  @callback get_run(Keyword.t()) :: {:ok, Run.t()} | {:error, :workflow_run_not_found}
  def get_run(by) do
    case Repo.get_by(Run, by) do
      %Run{} = run -> {:ok, run}
      nil -> {:error, :workflow_run_not_found}
    end
  end
end
