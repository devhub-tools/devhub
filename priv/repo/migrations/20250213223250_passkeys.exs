defmodule Devhub.Repo.Migrations.Passkeys do
  use Ecto.Migration

  def change do
    create table(:passkeys) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :raw_id, :text, null: false
      add :public_key, :binary, null: false
      add :aaguid, :binary

      timestamps()
    end
  end
end
