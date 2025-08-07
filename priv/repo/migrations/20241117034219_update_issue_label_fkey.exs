defmodule Devhub.Repo.Migrations.UpdateIssueLabelFkey do
  use Ecto.Migration

  def change do
    alter table(:linear_issues_labels) do
      modify :issue_id, references(:linear_issues, on_delete: :delete_all),
        from: references(:linear_issues)

      modify :label_id, references(:linear_labels, on_delete: :delete_all),
        from: references(:linear_labels)
    end
  end
end
