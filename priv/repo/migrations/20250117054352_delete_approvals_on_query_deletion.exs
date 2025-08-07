defmodule Devhub.Repo.Migrations.DeleteApprovalsOnQueryDeletion do
  use Ecto.Migration

  def change do
    drop constraint(:querydesk_query_approvals, "querydesk_query_approvals_query_id_fkey")

    alter table(:querydesk_query_approvals) do
      modify :query_id, references(:querydesk_queries, on_delete: :delete_all)
    end
  end
end
