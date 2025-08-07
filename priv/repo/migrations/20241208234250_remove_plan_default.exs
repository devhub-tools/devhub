defmodule Devhub.Repo.Migrations.RemovePlanDefault do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      modify :license_plan, :text, default: nil
    end
  end
end
