defmodule Devhub.QueryDesk.Actions.QueryAuditLog do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Repo

  @callback query_audit_log(Keyword.t()) :: [Query.t()]
  def query_audit_log(filters) do
    start_date = Timex.Timezone.convert(filters[:start_date], filters[:timezone])

    end_date =
      filters[:end_date] |> Timex.Timezone.convert(filters[:timezone]) |> Timex.end_of_day()

    query =
      from q in Query,
        join: c in assoc(q, :credential),
        join: d in assoc(c, :database),
        as: :database,
        join: u in assoc(q, :user),
        left_join: qc in assoc(q, :comments),
        left_join: qcu in assoc(qc, :created_by_user),
        left_join: a in assoc(q, :approvals),
        where: not q.is_system,
        where: not is_nil(q.executed_at),
        where: q.executed_at >= ^start_date,
        where: q.executed_at <= ^end_date,
        preload: [approvals: a, user: u, credential: {c, database: d}, comments: {qc, created_by_user: qcu}],
        order_by: [desc: q.executed_at],
        distinct: true,
        limit: 100

    query
    |> maybe_filter_database_id(filters[:database_id])
    |> query_filter(Keyword.take(filters, [:user_id, :query]))
    |> Repo.all()
  end

  defp maybe_filter_database_id(query, database_id) do
    if database_id do
      from [database: d] in query, where: d.id == ^database_id
    else
      query
    end
  end
end
