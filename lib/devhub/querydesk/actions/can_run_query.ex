defmodule Devhub.QueryDesk.Actions.CanRunQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Permissions
  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Repo

  @callback can_run_query?(Query.t()) :: boolean()
  def can_run_query?(%Query{executed_at: executed_at}) when is_struct(executed_at), do: false
  def can_run_query?(%Query{is_system: true}), do: true
  def can_run_query?(%Query{credential: %{reviews_required: 0}}), do: true

  def can_run_query?(%Query{credential: %{reviews_required: required}} = query) do
    get_approval_count(query) >= required
  end

  defp get_approval_count(query) do
    query =
      Repo.preload(
        query,
        [approvals: [approving_user: [organization_users: :roles]], credential: [database: :permissions]],
        force: true
      )

    query.approvals
    |> Enum.filter(fn approval ->
      organization_user = List.first(approval.approving_user.organization_users)

      not is_nil(organization_user) and approval.approving_user_id != query.user_id and
        DateTime.after?(approval.approved_at, query.updated_at) and
        Permissions.can?(:approve, query.credential.database, organization_user)
    end)
    |> length()
  end
end
