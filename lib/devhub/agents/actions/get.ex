defmodule Devhub.Agents.Actions.Get do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Agents.Schemas.Agent
  alias Devhub.Repo

  @callback get(Keyword.t()) :: {:ok, Agent.t()} | {:error, :agent_not_found}
  def get(by) do
    case Repo.get_by(Agent, by) do
      %Agent{} = agent ->
        {:ok, agent}

      nil ->
        {:error, :agent_not_found}
    end
  end
end
