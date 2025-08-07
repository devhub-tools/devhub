defmodule Devhub.Uptime.Actions.ListServices do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Uptime.Schemas.Check
  alias Devhub.Uptime.Schemas.Service

  @callback list_services(String.t()) :: [Service.t()]
  @callback list_services(String.t(), Keyword.t()) :: [Service.t()]
  def list_services(organization_id, opts \\ []) do
    preload_checks = Keyword.get(opts, :preload_checks, false)
    limit_checks = Keyword.get(opts, :limit_checks, 30)

    query =
      from s in Service,
        as: :service,
        where: s.organization_id == ^organization_id,
        order_by: [asc: s.name]

    query
    |> maybe_preload_checks(preload_checks, limit_checks)
    |> Repo.all()
  end

  defp maybe_preload_checks(query, true, limit_checks) do
    recent_checks_query =
      from c in Check,
        select: [
          :id,
          :service_id,
          :inserted_at,
          :status_code,
          :dns_time,
          :tls_time,
          :first_byte_time,
          :request_time,
          :status
        ],
        select_merge: %{row_number: over(row_number(), partition_by: c.service_id, order_by: [desc: c.inserted_at])},
        where: c.service_id == parent_as(:service).id,
        # reducing data to only the last 12 hours to improve performance
        where: c.inserted_at > ^DateTime.add(DateTime.utc_now(), -12, :hour)

    from s in query,
      left_lateral_join: c in subquery(recent_checks_query),
      on: c.row_number <= ^limit_checks,
      order_by: [desc: c.inserted_at],
      preload: [checks: c]
  end

  defp maybe_preload_checks(query, _preload_checks, _limit), do: query
end
