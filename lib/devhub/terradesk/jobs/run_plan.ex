defmodule Devhub.TerraDesk.Jobs.RunPlan do
  @moduledoc false
  use Oban.Worker, queue: :terradesk

  alias Devhub.TerraDesk

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    case TerraDesk.get_plan(id: id) do
      {:ok, %{status: :queued} = plan} ->
        TerraDesk.run_plan(plan)
        :ok

      _not_queued ->
        :ok
    end
  end
end
