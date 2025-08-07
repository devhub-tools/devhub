defmodule Devhub.Workflows.Jobs.RunWorkflow do
  @moduledoc false
  use Oban.Worker, queue: :workflows

  alias Devhub.Workflows

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    with {:ok, %{status: status} = run} when status in [:in_progress, :waiting_for_approval] <- Workflows.get_run(id: id) do
      Workflows.continue(run)
    end
  end
end
