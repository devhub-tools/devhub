defmodule Devhub.Repo.Migrations.AddSetupCompleteToOrganization do
  use Ecto.Migration

  def up do
    alter table(:organizations) do
      add :onboarding, :map
    end

    execute "UPDATE organizations SET onboarding = '{\"done\": true}'", ""
  end
end
