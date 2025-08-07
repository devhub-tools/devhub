defmodule Devhub.Uptime do
  @moduledoc false
  @behaviour Devhub.Uptime.Actions.CheckService
  @behaviour Devhub.Uptime.Actions.GetService
  @behaviour Devhub.Uptime.Actions.InsertOrUpdateService
  @behaviour Devhub.Uptime.Actions.Latency
  @behaviour Devhub.Uptime.Actions.ListChecks
  @behaviour Devhub.Uptime.Actions.ListServices
  @behaviour Devhub.Uptime.Actions.PubSub
  @behaviour Devhub.Uptime.Actions.SaveCheck
  @behaviour Devhub.Uptime.Actions.ServiceHistoryChart
  @behaviour Devhub.Uptime.Actions.TraceRequest
  @behaviour Devhub.Uptime.Actions.UptimePercentage

  alias Devhub.Uptime.Actions

  ###
  ### Services
  ###
  @impl Actions.GetService
  defdelegate get_service(by, opts \\ []), to: Actions.GetService

  @impl Actions.ListServices
  defdelegate list_services(organization_id, opts \\ []), to: Actions.ListServices

  @impl Actions.InsertOrUpdateService
  defdelegate insert_or_update_service(service, attrs), to: Actions.InsertOrUpdateService

  @impl Actions.UptimePercentage
  defdelegate uptime_percentage(service, duration), to: Actions.UptimePercentage

  @impl Actions.Latency
  defdelegate latency(service, duration), to: Actions.Latency

  @impl Actions.ServiceHistoryChart
  defdelegate service_history_chart(service, start_date, end_date), to: Actions.ServiceHistoryChart

  @impl Actions.TraceRequest
  defdelegate trace_request(service), to: Actions.TraceRequest

  ###
  ### Checks
  ###

  @impl Actions.CheckService
  defdelegate check_service(service), to: Actions.CheckService

  @impl Actions.ListChecks
  defdelegate list_checks(service, opts \\ []), to: Actions.ListChecks

  @impl Actions.SaveCheck
  defdelegate save_check!(attrs), to: Actions.SaveCheck

  ###
  ### PubSub
  ###
  @impl Actions.PubSub
  defdelegate subscribe_checks(service_id \\ "all"), to: Actions.PubSub

  @impl Actions.PubSub
  defdelegate unsubscribe_checks(service_id \\ "all"), to: Actions.PubSub
end
