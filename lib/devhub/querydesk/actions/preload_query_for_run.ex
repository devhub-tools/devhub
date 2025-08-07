defmodule Devhub.QueryDesk.Actions.PreloadQueryForRun do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Repo

  require Logger

  @callback preload_query_for_run(Query.t()) :: Query.t()
  def preload_query_for_run(query) do
    query =
      from q in Query,
        join: o in assoc(q, :organization),
        join: c in assoc(q, :credential),
        join: d in assoc(c, :database),
        left_join: u in assoc(q, :user),
        left_join: ou in assoc(u, :organization_users),
        on: ou.organization_id == q.organization_id,
        left_join: r in assoc(ou, :roles),
        left_join: p in assoc(d, :permissions),
        left_join: dpp in assoc(p, :data_protection_policy),
        left_join: dpc in assoc(dpp, :columns),
        left_join: ca in assoc(dpc, :custom_action),
        where: q.id == ^query.id,
        preload: [
          user: {u, organization_users: {ou, roles: r}},
          organization: o,
          credential: {
            c,
            database: {
              d,
              permissions:
                {p,
                 data_protection_policy: {
                   dpp,
                   columns: {dpc, custom_action: ca}
                 }}
            }
          }
        ]

    Repo.one(query)
  end
end
