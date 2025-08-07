defmodule Devhub.Uptime.Actions.InsertOrUpdateService do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Uptime.CheckJob
  alias Devhub.Uptime.Schemas.Service

  @callback insert_or_update_service(Service.t(), map()) :: {:ok, Service.t()}
  def insert_or_update_service(service, attrs) do
    service
    |> Service.changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      {:ok, service} ->
        %{id: service.id} |> CheckJob.new(scheduled_at: DateTime.utc_now()) |> Oban.insert()
        {:ok, service}

      error ->
        error
    end
  end
end
