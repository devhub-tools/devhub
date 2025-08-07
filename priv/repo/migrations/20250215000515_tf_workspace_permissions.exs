defmodule Devhub.Repo.Migrations.TfWorkspacePermissions do
  use Ecto.Migration

  def change do
    alter table(:object_permissions) do
      add :terraform_workspace_id, references(:terraform_workspaces, on_delete: :delete_all)
    end

    drop unique_index(:object_permissions, [:database_id, :organization_user_id])

    create unique_index(:object_permissions, [:database_id, :organization_user_id],
             where: "database_id IS NOT NULL"
           )

    create unique_index(:object_permissions, [:terraform_workspace_id, :organization_user_id],
             where: "terraform_workspace_id IS NOT NULL"
           )
  end
end
