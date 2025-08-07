defmodule Devhub.Repo.Migrations.ImproveLabels do
  use Ecto.Migration

  def change do
    alter table(:linear_labels) do
      add :is_group, :boolean, null: false, default: false
      add :parent_label_id, references(:linear_labels)
      add :team_id, references(:linear_teams)
    end
  end
end
