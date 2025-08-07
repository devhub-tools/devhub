defmodule Devhub.QueryDesk.Jobs.CleanupExpiredSharedQueries do
  @moduledoc false
  use Oban.Worker, queue: :querydesk

  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.SharedQuery
  alias Devhub.Repo

  def perform(_args) do
    expired_queries =
      from sq in SharedQuery,
        where: sq.expires_at < ^DateTime.utc_now()

    Repo.delete_all(expired_queries)

    :ok
  end
end
