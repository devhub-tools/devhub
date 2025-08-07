defmodule Devhub.Agents.Actions.Online do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Agents.Schemas.Agent

  @callback online?(Agent.t() | String.t()) :: boolean()
  def online?(%Agent{id: id}) do
    do_check(id)
  end

  def online?(id) when is_binary(id) do
    do_check(id)
  end

  defp do_check(id) do
    case :ets.lookup(DevhubWeb.AgentConnection, id) do
      [{^id, _pid}] -> true
      _not_online -> false
    end
  end
end
