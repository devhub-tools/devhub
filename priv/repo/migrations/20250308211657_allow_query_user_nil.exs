defmodule Devhub.Repo.Migrations.AllowQueryUserNil do
  use Ecto.Migration

  def change do
    alter table(:querydesk_queries) do
      modify :user_id, :text, null: true
    end
  end
end
