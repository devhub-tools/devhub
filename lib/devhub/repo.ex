defmodule Devhub.Repo do
  use Ecto.Repo,
    otp_app: :devhub,
    adapter: Ecto.Adapters.Postgres
end

defmodule Devhub.QueryDesk.PostgresRepo do
  use Ecto.Repo,
    otp_app: :devhub,
    adapter: Ecto.Adapters.Postgres
end

defmodule Devhub.QueryDesk.MySQLRepo do
  use Ecto.Repo,
    otp_app: :devhub,
    adapter: Ecto.Adapters.MyXQL
end

defmodule Devhub.QueryDesk.ClickHouseRepo do
  use Ecto.Repo,
    otp_app: :devhub,
    adapter: Ecto.Adapters.ClickHouse
end

# defmodule Devhub.QueryDesk.SQLServerRepo do
#   use Ecto.Repo,
#     otp_app: :query_desk,
#     adapter: Ecto.Adapters.TDS
# end

Postgrex.Types.define(
  Devhub.QueryDesk.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Pgvector.extensions() ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
