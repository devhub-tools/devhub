defmodule Devhub.Repo.Migrations.AiChat do
  use Ecto.Migration

  def change do
    create table(:ai_conversations) do
      add :organization_id, references(:organizations), null: false
      add :user_id, references(:users), null: false
      add :title, :text, null: false

      timestamps()
    end

    create index(:ai_conversations, [:organization_id, :user_id])

    create table(:ai_conversation_messages) do
      add :organization_id, references(:organizations), null: false
      add :conversation_id, references(:ai_conversations), null: false
      add :sender, :text, null: false
      add :message, :text, null: false

      timestamps()
    end

    create index(:ai_conversation_messages, [:conversation_id])
  end
end
