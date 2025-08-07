defmodule Devhub.Repo.Migrations.LinearPriority do
  use Ecto.Migration

  def change do
    alter table(:linear_issues) do
      add :priority, :integer
      add :priority_label, :text
    end
  end
end
