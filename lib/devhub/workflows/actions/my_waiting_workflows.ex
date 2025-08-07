defmodule Devhub.Workflows.Actions.MyWaitingWorkflows do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Permissions
  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser
  alias Devhub.Workflows.Schemas.Run

  @callback my_waiting_workflows(OrganizationUser.t()) :: map()
  def my_waiting_workflows(organization_user) do
    query =
      from r in Run,
        where: r.organization_id == ^organization_user.organization_id,
        where: r.status == :waiting_for_approval,
        preload: [steps: [workflow_step: :permissions]]

    query
    |> Repo.all()
    |> Enum.reduce(%{}, fn run, acc ->
      count = Map.get(acc, run.workflow_id, 0)

      step = Enum.find(run.steps, &(&1.status in [:pending, :waiting_for_approval]))

      if Permissions.can?(:approve, step.workflow_step, organization_user) do
        Map.put(acc, run.workflow_id, count + 1)
      else
        acc
      end
    end)
  end
end
