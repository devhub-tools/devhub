defmodule Devhub.Workflows.Actions.ApproveStep do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Permissions
  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser
  alias Devhub.Workflows
  alias Devhub.Workflows.Jobs.RunWorkflow
  alias Devhub.Workflows.Schemas.Run
  alias Devhub.Workflows.Schemas.Run.Step

  @callback approve_step(Run.t(), Step.t(), OrganizationUser.t()) ::
              {:ok, Run.t()} | {:error, :invalid_input} | {:error, :failed_to_approve_step}
  def approve_step(run, step, organization_user) do
    if Permissions.can?(:approve, step.workflow_step, organization_user) do
      do_approve_step(run, step, organization_user)
    else
      {:error, "You do not have permission to approve this step"}
    end
  end

  defp do_approve_step(run, approving_step, organization_user) do
    approvals =
      Enum.uniq_by(
        [%{organization_user_id: organization_user.id, approved_at: DateTime.utc_now()} | approving_step.approvals],
        & &1.organization_user_id
      )

    status =
      if Enum.count(approvals) >= approving_step.action.reviews_required do
        :succeeded
      else
        :waiting_for_approval
      end

    workflow_status = if status == :succeeded, do: :in_progress, else: :waiting_for_approval

    steps =
      Enum.map(
        run.steps,
        fn step ->
          step =
            if(approving_step.workflow_step_id == step.workflow_step_id,
              do: Map.merge(approving_step, %{status: status, approvals: approvals}),
              else: step
            )

          type = PolymorphicEmbed.get_polymorphic_type(step.__struct__, :action, step.action)
          action = step.action |> Map.from_struct() |> Map.put(:__type__, type)

          step
          |> Map.from_struct()
          |> Map.put(:action, action)
        end
      )

    changeset = Run.changeset(run, %{status: workflow_status, steps: steps})

    Repo.transaction(fn ->
      with {:ok, run} <- Repo.update(changeset),
           {:ok, _job} <- %{id: run.id} |> RunWorkflow.new() |> Oban.insert() do
        Workflows.preload_run(run)
      else
        _error -> Repo.rollback(:failed_to_approve_step)
      end
    end)
  end
end
