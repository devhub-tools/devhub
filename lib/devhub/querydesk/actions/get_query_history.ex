defmodule Devhub.QueryDesk.Actions.GetQueryHistory do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.Query

  @callback get_query_history(String.t(), Keyword.t()) :: [
              %{id: String.t(), query: String.t(), executed_at: DateTime.t()}
            ]
  def get_query_history(database_id, filters) do
    query =
      from q in Query,
        select: %{id: q.id, query: q.query, executed_at: q.executed_at},
        join: c in assoc(q, :credential),
        where: c.database_id == ^database_id,
        where: not q.is_system,
        where: not is_nil(q.executed_at),
        order_by: [desc: q.executed_at],
        limit: 50

    query
    |> query_filter(filters)
    |> Devhub.Repo.all()
  end
end
