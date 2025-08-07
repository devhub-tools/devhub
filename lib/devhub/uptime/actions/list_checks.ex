defmodule Devhub.Uptime.Actions.ListChecks do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Uptime.Schemas.Check
  alias Devhub.Uptime.Schemas.Service

  @callback list_checks(Service.t(), Keyword.t()) :: [Check.t()]
  def list_checks(service, opts) do
    filters = Keyword.get(opts, :filters, [])
    limit = Keyword.get(opts, :limit, 20)
    cursor = Keyword.get(opts, :cursor)

    query =
      from c in Check,
        where: c.service_id == ^service.id,
        limit: ^limit,
        # inserted_at and id should have the same order but we need to use inserted_at for index performance
        order_by: [desc: c.inserted_at]

    filters = Keyword.take(filters, [:status, :request_time, :inserted_at])

    query
    |> query_filter(filters)
    |> paginate(cursor)
    |> Repo.all()
  end

  defp paginate(query, {:next, cursor}) do
    where(query, [c], c.id < ^cursor)
  end

  defp paginate(query, {:prev, cursor}) do
    where(query, [c], c.id > ^cursor)
  end

  defp paginate(query, _cursor) do
    query
  end
end
