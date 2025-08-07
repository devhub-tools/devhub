defmodule Devhub.Repo.Migrations.RemoveStepSecrets do
  use Ecto.Migration

  def change do
    alter table(:workflow_steps) do
      remove :secrets
    end
  end
end
