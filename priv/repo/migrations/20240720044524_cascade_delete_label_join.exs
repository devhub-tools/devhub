defmodule Devhub.Repo.Migrations.CascadeDeleteLabelJoin do
  use Ecto.Migration

  def change do
    drop constraint(:linear_issues_labels, "linear_issues_labels_label_id_fkey")
    drop constraint(:linear_issues_labels, "linear_issues_labels_issue_id_fkey")

    alter table(:linear_issues_labels) do
      modify :issue_id, references(:linear_issues, on_delete: :delete_all)
      modify :label_id, references(:linear_labels, on_delete: :delete_all)
    end
  end
end
