defmodule Devhub.Repo.Migrations.Calendar do
  use Ecto.Migration

  def change do
    create table(:calendar_events) do
      add :organization_id, references(:organizations), null: false
      add :linear_user_id, references(:linear_users)
      add :external_id, :text
      add :title, :text
      add :color, :text, default: "red", null: false
      add :person, :text
      add :start_date, :date
      add :end_date, :date
    end

    create unique_index(:calendar_events, [:organization_id, :external_id])
  end
end
