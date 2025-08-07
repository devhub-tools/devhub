defmodule Devhub.Repo.Migrations.MfaRequired do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :mfa_required, :boolean, default: false, null: false
    end
  end
end
