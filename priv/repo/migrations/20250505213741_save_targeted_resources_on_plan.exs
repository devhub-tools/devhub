defmodule Devhub.Repo.Migrations.SaveTargetedResourcesOnPlan do
  use Ecto.Migration

  def change do
    alter table(:terraform_plans) do
      add :targeted_resources, {:array, :string}
    end
  end
end
