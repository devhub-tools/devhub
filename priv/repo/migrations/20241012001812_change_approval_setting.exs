defmodule Devhub.Repo.Migrations.ChangeApprovalSetting do
  use Ecto.Migration

  def change do
    alter table(:terraform_workspaces) do
      add :run_plans_automatically, :boolean, default: false
    end
  end
end
