defmodule Devhub.TerraDesk.TerraformStateCache do
  @moduledoc false
  use GenServer

  alias Devhub.TerraDesk.Schemas.Workspace

  @callback get_resources(Workspace.t()) :: [String.t()] | nil
  def get_resources(workspace) do
    GenServer.call(__MODULE__, {:get_resources, workspace})
  end

  @callback update_resources(Workspace.t(), [String.t()]) :: :ok
  def update_resources(workspace, resources) do
    GenServer.call(__MODULE__, {:update_resources, workspace, resources})
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_resources, workspace}, _from, state) do
    {:reply, state[workspace.id], state}
  end

  def handle_call({:update_resources, workspace, resources}, _from, state) do
    {:reply, :ok, Map.put(state, workspace.id, resources)}
  end
end
