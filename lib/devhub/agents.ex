defmodule Devhub.Agents do
  @moduledoc false

  @behaviour Devhub.Agents.Actions.Create
  @behaviour Devhub.Agents.Actions.Get
  @behaviour Devhub.Agents.Actions.List
  @behaviour Devhub.Agents.Actions.Online
  @behaviour Devhub.Agents.Actions.Update

  alias Devhub.Agents.Actions

  @impl Actions.List
  defdelegate list(organization_id), to: Actions.List

  @impl Actions.Get
  defdelegate get(by), to: Actions.Get

  @impl Actions.Create
  defdelegate create(name, organization), to: Actions.Create

  @impl Actions.Update
  defdelegate update(agent, params), to: Actions.Update

  @impl Actions.Online
  defdelegate online?(agent), to: Actions.Online
end
