defmodule Devhub.Repo.Migrations.WorkflowLinearLabelTrigger do
  use Ecto.Migration

  def change do
    alter table(:workflows) do
      add :trigger_linear_label_id, references(:linear_labels, on_delete: :nilify_all)
    end

    alter table(:workflow_runs) do
      add :triggered_by_linear_issue_id, references(:linear_issues)
    end
  end
end
