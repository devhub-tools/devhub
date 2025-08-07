defmodule Devhub.QueryDesk do
  @moduledoc false

  @behaviour Devhub.QueryDesk.Actions.AnalyzeQuery
  @behaviour Devhub.QueryDesk.Actions.CanAccessDatabase
  @behaviour Devhub.QueryDesk.Actions.CancelQuery
  @behaviour Devhub.QueryDesk.Actions.CanRunQuery
  @behaviour Devhub.QueryDesk.Actions.CreateComment
  @behaviour Devhub.QueryDesk.Actions.CreateDatabase
  @behaviour Devhub.QueryDesk.Actions.CreateQuery
  @behaviour Devhub.QueryDesk.Actions.DeleteComment
  @behaviour Devhub.QueryDesk.Actions.DeleteDatabase
  @behaviour Devhub.QueryDesk.Actions.DeleteQuery
  @behaviour Devhub.QueryDesk.Actions.DeleteSavedQuery
  @behaviour Devhub.QueryDesk.Actions.DeleteSharedQuery
  @behaviour Devhub.QueryDesk.Actions.FormatField
  @behaviour Devhub.QueryDesk.Actions.GetDatabase
  @behaviour Devhub.QueryDesk.Actions.GetQuery
  @behaviour Devhub.QueryDesk.Actions.GetQueryHistory
  @behaviour Devhub.QueryDesk.Actions.GetSavedQuery
  @behaviour Devhub.QueryDesk.Actions.GetSharedQuery
  @behaviour Devhub.QueryDesk.Actions.ListCredentialOptions
  @behaviour Devhub.QueryDesk.Actions.ListDatabases
  @behaviour Devhub.QueryDesk.Actions.ListSavedQueries
  @behaviour Devhub.QueryDesk.Actions.ListSharedQueries
  @behaviour Devhub.QueryDesk.Actions.ParsePlan
  @behaviour Devhub.QueryDesk.Actions.PinDatabase
  @behaviour Devhub.QueryDesk.Actions.PreloadQueryForRun
  @behaviour Devhub.QueryDesk.Actions.QueryAuditLog
  @behaviour Devhub.QueryDesk.Actions.ReplaceQueryVariables
  @behaviour Devhub.QueryDesk.Actions.RunQuery
  @behaviour Devhub.QueryDesk.Actions.SaveQuery
  @behaviour Devhub.QueryDesk.Actions.SaveSharedQuery
  @behaviour Devhub.QueryDesk.Actions.SetupDefaultDatabase
  @behaviour Devhub.QueryDesk.Actions.TestConnection
  @behaviour Devhub.QueryDesk.Actions.UnpinDatabase
  @behaviour Devhub.QueryDesk.Actions.UpdateComment
  @behaviour Devhub.QueryDesk.Actions.UpdateDatabase
  @behaviour Devhub.QueryDesk.Actions.UpdateQuery
  @behaviour Devhub.QueryDesk.Actions.UpdateSavedQuery

  alias Devhub.QueryDesk.Actions

  ### DATABASES ###

  @impl Actions.ListDatabases
  defdelegate list_databases(organization_user, opts \\ []), to: Actions.ListDatabases

  @impl Actions.ListCredentialOptions
  defdelegate list_credential_options(organization_user), to: Actions.ListCredentialOptions

  @impl Actions.GetDatabase
  defdelegate get_database(by, opts \\ []), to: Actions.GetDatabase

  @impl Actions.CreateDatabase
  defdelegate create_database(params), to: Actions.CreateDatabase

  @impl Actions.PinDatabase
  defdelegate pin_database(organization_user, database), to: Actions.PinDatabase

  @impl Actions.UnpinDatabase
  defdelegate unpin_database(pinned_database), to: Actions.UnpinDatabase

  @impl Actions.UpdateDatabase
  defdelegate update_database(database, params), to: Actions.UpdateDatabase

  @impl Actions.DeleteDatabase
  defdelegate delete_database(database), to: Actions.DeleteDatabase

  @impl Actions.CanAccessDatabase
  defdelegate can_access_database?(database, organization_user), to: Actions.CanAccessDatabase

  @impl Actions.TestConnection
  defdelegate test_connection(database, credential_id), to: Actions.TestConnection

  @impl Actions.SetupDefaultDatabase
  defdelegate setup_default_database(organization), to: Actions.SetupDefaultDatabase

  ### QUERIES ###

  @impl Actions.GetQuery
  defdelegate get_query(by), to: Actions.GetQuery

  @impl Actions.GetQueryHistory
  defdelegate get_query_history(database_id, filters), to: Actions.GetQueryHistory

  @impl Actions.CreateQuery
  defdelegate create_query(params), to: Actions.CreateQuery

  @impl Actions.UpdateQuery
  defdelegate update_query(query, params), to: Actions.UpdateQuery

  @impl Actions.RunQuery
  defdelegate run_query(query, opts \\ []), to: Actions.RunQuery

  @impl Actions.CanRunQuery
  defdelegate can_run_query?(query), to: Actions.CanRunQuery

  @impl Actions.GetSharedQuery
  defdelegate get_shared_query(by), to: Actions.GetSharedQuery

  @impl Actions.SaveSharedQuery
  defdelegate save_shared_query(params), to: Actions.SaveSharedQuery

  @impl Actions.DeleteSharedQuery
  defdelegate delete_shared_query(shared_query), to: Actions.DeleteSharedQuery

  @impl Actions.ListSharedQueries
  defdelegate list_shared_queries(organization_user), to: Actions.ListSharedQueries

  @impl Actions.DeleteQuery
  defdelegate delete_query(query, user), to: Actions.DeleteQuery

  @impl Actions.QueryAuditLog
  defdelegate query_audit_log(filters), to: Actions.QueryAuditLog

  @impl Actions.ReplaceQueryVariables
  defdelegate replace_query_variables(query, variables), to: Actions.ReplaceQueryVariables

  @impl Actions.PreloadQueryForRun
  defdelegate preload_query_for_run(query), to: Actions.PreloadQueryForRun

  @impl Actions.FormatField
  defdelegate format_field(field), to: Actions.FormatField

  @impl Actions.CancelQuery
  defdelegate cancel_query(query, query_task), to: Actions.CancelQuery

  @impl Actions.AnalyzeQuery
  defdelegate analyze_query(query), to: Actions.AnalyzeQuery

  @impl Actions.ParsePlan
  defdelegate parse_plan(json), to: Actions.ParsePlan

  ### QUERY COMMENTS ###

  @impl Actions.CreateComment
  defdelegate create_comment(query, user, comment), to: Actions.CreateComment

  @impl Actions.DeleteComment
  defdelegate delete_comment(comment), to: Actions.DeleteComment

  @impl Actions.UpdateComment
  defdelegate update_comment(comment, params), to: Actions.UpdateComment

  ### SAVED QUERIES ###

  @impl Actions.ListSavedQueries
  defdelegate list_saved_queries(organization_user, opts \\ []), to: Actions.ListSavedQueries

  @impl Actions.SaveQuery
  defdelegate save_query(params), to: Actions.SaveQuery

  @impl Actions.GetSavedQuery
  defdelegate get_saved_query(by), to: Actions.GetSavedQuery

  @impl Actions.UpdateSavedQuery
  defdelegate update_saved_query(saved_query, params), to: Actions.UpdateSavedQuery

  @impl Actions.DeleteSavedQuery
  defdelegate delete_saved_query(saved_query), to: Actions.DeleteSavedQuery
end
