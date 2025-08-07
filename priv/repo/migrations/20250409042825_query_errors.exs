defmodule Devhub.Repo.Migrations.QueryErrors do
  use Ecto.Migration

  def change do
    alter table(:querydesk_queries) do
      add :error, :text
    end

    create_if_not_exists index(:querydesk_queries, [:executed_at])
    create_if_not_exists index(:querydesk_queries, [:credential_id])
  end
end
