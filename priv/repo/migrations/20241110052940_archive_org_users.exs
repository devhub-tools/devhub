defmodule Devhub.Repo.Migrations.ArchiveOrgUsers do
  use Ecto.Migration

  def change do
    alter table(:organization_users) do
      add :archived_at, :utc_datetime
    end
  end
end
