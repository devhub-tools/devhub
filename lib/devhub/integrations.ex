defmodule Devhub.Integrations do
  @moduledoc false

  @behaviour Devhub.Integrations.Actions.Create
  @behaviour Devhub.Integrations.Actions.CreateIcal
  @behaviour Devhub.Integrations.Actions.DeleteIcal
  @behaviour Devhub.Integrations.Actions.GetBy
  @behaviour Devhub.Integrations.Actions.GetPullRequests
  @behaviour Devhub.Integrations.Actions.GetTasks
  @behaviour Devhub.Integrations.Actions.InsertOrUpdate
  @behaviour Devhub.Integrations.Actions.List
  @behaviour Devhub.Integrations.Actions.Update
  @behaviour Devhub.Integrations.Actions.UpdateIcal

  alias Devhub.Integrations.Actions

  @impl Actions.InsertOrUpdate
  defdelegate insert_or_update(integration, attrs), to: Actions.InsertOrUpdate

  @impl Actions.List
  defdelegate list(organization, type \\ :all), to: Actions.List

  @impl Actions.Create
  defdelegate create(params), to: Actions.Create

  @impl Actions.Update
  defdelegate update(integration, params), to: Actions.Update

  @impl Actions.CreateIcal
  defdelegate create_ical(params), to: Actions.CreateIcal

  @impl Actions.UpdateIcal
  defdelegate update_ical(integration, params), to: Actions.UpdateIcal

  @impl Actions.DeleteIcal
  defdelegate delete_ical(integration), to: Actions.DeleteIcal

  @impl Actions.GetBy
  defdelegate get_by(by), to: Actions.GetBy

  @impl Actions.GetTasks
  defdelegate get_tasks(filter, opts), to: Actions.GetTasks

  @impl Actions.GetPullRequests
  defdelegate get_pull_requests(filter, opts), to: Actions.GetPullRequests
end
