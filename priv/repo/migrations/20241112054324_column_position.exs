defmodule Devhub.Repo.Migrations.ColumnPosition do
  use Ecto.Migration

  def change do
    alter table(:querydesk_database_columns) do
      add :position, :integer
    end
  end
end
