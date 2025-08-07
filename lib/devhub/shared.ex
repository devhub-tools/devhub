defmodule Devhub.Shared do
  @moduledoc false

  @behaviour Devhub.Shared.Actions.CreateObjectLabel
  @behaviour Devhub.Shared.Actions.DeleteLabel
  @behaviour Devhub.Shared.Actions.InsertOrUpdateLabel
  @behaviour Devhub.Shared.Actions.ListLabels
  @behaviour Devhub.Shared.Actions.RemoveObjectLabel

  alias Devhub.Shared.Actions

  @impl Actions.InsertOrUpdateLabel
  defdelegate insert_or_update_label(label, params), to: Actions.InsertOrUpdateLabel

  @impl Actions.DeleteLabel
  defdelegate delete_label(label), to: Actions.DeleteLabel

  @impl Actions.ListLabels
  defdelegate list_labels(organization_id), to: Actions.ListLabels

  @impl Actions.CreateObjectLabel
  defdelegate create_object_label(params), to: Actions.CreateObjectLabel

  @impl Actions.RemoveObjectLabel
  defdelegate remove_object_label(by), to: Actions.RemoveObjectLabel
end
