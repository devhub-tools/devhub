defmodule Devhub.Repo.Migrations.AddOrgIdToApproval do
  use Ecto.Migration

  def change do
    alter table(:querydesk_query_approvals) do
      add :organization_id, references(:organizations)
    end

    execute """
            UPDATE querydesk_query_approvals
            SET organization_id = q.organization_id
            FROM querydesk_queries q
            WHERE q.id = query_id
            """,
            ""
  end
end
