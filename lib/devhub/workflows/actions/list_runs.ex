defmodule Devhub.Workflows.Actions.ListRuns do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Run

  @callback list_runs(String.t(), Keyword.t()) :: [Run.t()]
  def list_runs(workflow_id, opts) do
    filters = Keyword.get(opts, :filters, [])

    query =
      from i in Run,
        where: i.workflow_id == ^workflow_id,
        order_by: [desc: i.inserted_at],
        limit: 20,
        preload: [:triggered_by_user]

    query =
      if filters[:status] == "pending" do
        where(query, [i], i.status in [:in_progress, :waiting_for_approval])
      else
        query
      end

    Repo.all(query)
  end
end
