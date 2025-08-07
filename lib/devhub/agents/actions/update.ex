defmodule Devhub.Agents.Actions.Update do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Agents.Schemas.Agent
  alias Devhub.Repo

  @callback update(Agent.t(), map()) :: {:ok, Agent.t()} | {:error, Ecto.Changeset.t()}
  def update(agent, params) do
    agent
    |> Agent.update_changeset(params)
    |> Repo.update()
  end
end
