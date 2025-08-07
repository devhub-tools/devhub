defmodule Devhub.Uptime.Actions.GetService do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Uptime.Schemas.Check
  alias Devhub.Uptime.Schemas.Service

  @callback get_service(Keyword.t()) :: {:ok, Service.t()}
  @callback get_service(Keyword.t(), Keyword.t()) :: {:ok, Service.t()}
  def get_service(by, opts \\ []) do
    preload_checks = Keyword.get(opts, :preload_checks, false)
    limit_checks = Keyword.get(opts, :limit_checks, 30)

    from(s in Service, where: ^by)
    |> maybe_preload_checks(preload_checks, limit_checks)
    |> Repo.one()
    |> case do
      %Service{} = service -> {:ok, service}
      nil -> {:error, :service_not_found}
    end
  end

  defp maybe_preload_checks(query, true, limit_checks) do
    recent_checks = from(c in Check, order_by: [desc: c.inserted_at], limit: ^limit_checks)
    from query, preload: [checks: ^recent_checks]
  end

  defp maybe_preload_checks(query, _preload_checks, _limit), do: query
end
