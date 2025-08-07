defmodule Devhub.Repo.Migrations.WorkspaceAgent do
  use Ecto.Migration

  def change do
    alter table(:terraform_workspaces) do
      add :agent_id, references(:agents)
    end
  end
end
