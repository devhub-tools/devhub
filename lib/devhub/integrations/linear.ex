defmodule Devhub.Integrations.Linear do
  @moduledoc false

  @behaviour Devhub.Integrations.Linear.Actions.DeleteIssue
  @behaviour Devhub.Integrations.Linear.Actions.DeleteLabel
  @behaviour Devhub.Integrations.Linear.Actions.DeleteProject
  @behaviour Devhub.Integrations.Linear.Actions.GetLabel
  @behaviour Devhub.Integrations.Linear.Actions.ImportIssues
  @behaviour Devhub.Integrations.Linear.Actions.ImportLabels
  @behaviour Devhub.Integrations.Linear.Actions.ImportProjects
  @behaviour Devhub.Integrations.Linear.Actions.ImportUsers
  @behaviour Devhub.Integrations.Linear.Actions.ListLabels
  @behaviour Devhub.Integrations.Linear.Actions.ListTeams
  @behaviour Devhub.Integrations.Linear.Actions.Projects
  @behaviour Devhub.Integrations.Linear.Actions.UpdateLabel
  @behaviour Devhub.Integrations.Linear.Actions.UpdateLinearTeam
  @behaviour Devhub.Integrations.Linear.Actions.UpdateUser
  @behaviour Devhub.Integrations.Linear.Actions.UpsertIssue
  @behaviour Devhub.Integrations.Linear.Actions.UpsertLabel
  @behaviour Devhub.Integrations.Linear.Actions.UpsertProject
  @behaviour Devhub.Integrations.Linear.Actions.UpsertUser
  @behaviour Devhub.Integrations.Linear.Actions.Users

  alias Devhub.Integrations.Linear.Actions

  require Logger

  ### USERS ###

  @impl Actions.Users
  defdelegate users(organization_id, team_id \\ nil), to: Actions.Users

  @impl Actions.ImportUsers
  defdelegate import_users(integration), to: Actions.ImportUsers

  @impl Actions.UpsertUser
  defdelegate upsert_user(params), to: Actions.UpsertUser

  @impl Actions.UpdateUser
  defdelegate update_user(user, params), to: Actions.UpdateUser

  ### TEAMS ###

  @impl Actions.ListTeams
  defdelegate list_teams(organization_id), to: Actions.ListTeams

  @impl Actions.UpdateLinearTeam
  defdelegate update_linear_team(team, params), to: Actions.UpdateLinearTeam

  ### LABELS ###

  @impl Actions.ListLabels
  defdelegate list_labels(organization_id), to: Actions.ListLabels

  @impl Actions.GetLabel
  defdelegate get_label(by), to: Actions.GetLabel

  @impl Actions.ImportLabels
  defdelegate import_labels(integration), to: Actions.ImportLabels

  @impl Actions.UpsertLabel
  defdelegate upsert_label(integration, label), to: Actions.UpsertLabel

  @impl Actions.UpdateLabel
  defdelegate update_label(label, params), to: Actions.UpdateLabel

  @impl Actions.DeleteLabel
  defdelegate delete_label(integration, external_id), to: Actions.DeleteLabel

  ### PROJECTS ###

  @impl Actions.Projects
  defdelegate projects(organization_id), to: Actions.Projects

  @impl Actions.ImportProjects
  defdelegate import_projects(integration, since), to: Actions.ImportProjects

  @impl Actions.UpsertProject
  defdelegate upsert_project(integration, project), to: Actions.UpsertProject

  @impl Actions.DeleteProject
  defdelegate delete_project(integration, external_id), to: Actions.DeleteProject

  ### ISSUES ###

  @impl Actions.ImportIssues
  defdelegate import_issues(integration, since), to: Actions.ImportIssues

  @impl Actions.UpsertIssue
  defdelegate upsert_issue(integration, issue), to: Actions.UpsertIssue

  @impl Actions.DeleteIssue
  defdelegate delete_issue(integration, external_id), to: Actions.DeleteIssue
end
