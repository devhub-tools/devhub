defmodule Devhub.Release do
  @moduledoc false

  require Logger

  def wait_for_database_ready(count \\ 0)

  def wait_for_database_ready(120) do
    Logger.error("Database not ready after 120 seconds")
    System.stop(1)
  end

  def wait_for_database_ready(count) do
    database_ready? =
      Enum.all?(repos(), fn repo ->
        case Ecto.Migrator.with_repo(repo, &Ecto.Adapters.SQL.query(&1, "SELECT 1")) do
          {:ok, {:ok, %Postgrex.Result{}}, _app} -> true
          _error -> false
        end
      end)

    if !database_ready? do
      if rem(count, 5) == 0 do
        Logger.info("Waiting for database to be ready...")
      end

      :timer.sleep(1000)
      wait_for_database_ready(count + 1)
    end

    :ok
  rescue
    _error ->
      :timer.sleep(1000)
      wait_for_database_ready(count + 1)
  end

  def migrate do
    for repo <- repos() do
      {:ok, _fun_return, _app} =
        Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _fun_return, _app} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(:devhub)
    Application.ensure_all_started(:sentry)
    Application.fetch_env!(:devhub, :ecto_repos)
  end
end
