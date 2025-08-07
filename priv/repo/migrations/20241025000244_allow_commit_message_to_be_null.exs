defmodule Devhub.Repo.Migrations.AllowCommitMessageToBeNull do
  use Ecto.Migration

  def change do
    alter table(:commits) do
      modify :message, :text, null: true
    end
  end
end
