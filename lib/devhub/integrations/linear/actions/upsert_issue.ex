defmodule Devhub.Integrations.Linear.Actions.UpsertIssue do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Integrations.Linear.Actions.UpsertUser

  alias Devhub.Integrations.Linear.Issue
  alias Devhub.Integrations.Linear.Label
  alias Devhub.Integrations.Linear.Team
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo
  alias Devhub.Workflows

  @callback upsert_issue(Integration.t(), map()) :: Issue.t()
  def upsert_issue(integration, issue) do
    # the webhook doesn't nest labels under node like the graphql response
    labels_from_issue =
      case issue["labels"] do
        %{"nodes" => labels} -> labels
        labels when is_list(labels) -> labels
      end

    labels = Enum.map(labels_from_issue, &Repo.get_by!(Label, external_id: &1["id"]))

    user =
      if issue["assignee"] do
        {:ok, user} =
          upsert_user(%{
            organization_id: integration.organization_id,
            external_id: issue["assignee"]["id"],
            name: issue["assignee"]["name"]
          })

        user
      end

    team =
      if issue["team"] do
        {:ok, team} = upsert_team(integration, issue)
        team
      end

    %{
      organization_id: integration.organization_id,
      linear_user_id: user && user.id,
      linear_team_id: team && team.id,
      archived_at: issue["archivedAt"],
      canceled_at: issue["canceledAt"],
      completed_at: issue["completedAt"],
      created_at: issue["createdAt"],
      estimate: issue["estimate"],
      external_id: issue["id"],
      identifier: issue["identifier"],
      priority_label: issue["priorityLabel"],
      priority: issue["priority"],
      started_at: issue["startedAt"],
      state: issue["state"],
      title: issue["title"],
      url: issue["url"]
    }
    |> do_upsert_issue(labels)
    |> maybe_trigger_workflow_run(issue["description"])
  end

  defp do_upsert_issue(params, labels) do
    params
    |> Issue.changeset()
    |> Repo.insert!(
      on_conflict:
        {:replace,
         [
           :archived_at,
           :canceled_at,
           :completed_at,
           :created_at,
           :estimate,
           :identifier,
           :linear_team_id,
           :linear_user_id,
           :priority_label,
           :priority,
           :started_at,
           :state,
           :title,
           :url
         ]},
      conflict_target: [:organization_id, :external_id],
      returning: true
    )
    |> Repo.preload(:labels)
    |> Issue.labels_changeset(labels)
    |> Repo.update!()
  end

  defp upsert_team(integration, issue) do
    %{
      organization_id: integration.organization_id,
      external_id: issue["team"]["id"],
      name: issue["team"]["name"],
      key: issue["team"]["key"]
    }
    |> Team.changeset()
    |> Repo.insert(
      on_conflict: {:replace, [:name, :key]},
      conflict_target: [:organization_id, :external_id],
      returning: true
    )
  end

  defp maybe_trigger_workflow_run(issue, description) do
    label_ids = Enum.map(issue.labels, & &1.id)

    # Parse workflow inputs from description if present
    input_params =
      if String.contains?(description || "", "Workflow inputs:") do
        description
        |> String.split("Workflow inputs:", parts: 2)
        |> List.last()
        |> String.trim()
        |> String.split("\n", trim: true)
        |> Enum.take_while(fn line -> String.contains?(line, ":") end)
        |> Map.new(fn line ->
          [key, value] = String.split(line, ":", parts: 2)
          {String.trim(key), String.trim(value)}
        end)
      else
        %{}
      end

    input_params = Map.put(input_params, "triggered_by_linear_issue_id", issue.id)

    with workflows when workflows != [] <-
           Workflows.list_workflows(issue.organization_id, trigger_linear_label_id: {:in, label_ids}) do
      issue = Repo.preload(issue, :workflow_runs)
      already_triggered = Enum.map(issue.workflow_runs, & &1.workflow_id)

      workflows
      |> Enum.filter(&(&1.id not in already_triggered))
      |> Repo.preload(steps: [permissions: [organization_user: :user]])
      |> Enum.each(&Workflows.run_workflow(&1, input_params))
    end

    issue
  end
end
