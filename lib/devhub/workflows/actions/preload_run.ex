defmodule Devhub.Workflows.Actions.PreloadRun do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Run

  @callback preload_run(Run.t()) :: Run.t()
  def preload_run(run) do
    Repo.preload(
      run,
      [
        :triggered_by_user,
        :triggered_by_linear_issue,
        :workflow,
        steps: [
          :query,
          workflow_step: [permissions: [:role, organization_user: :user]],
          approvals: [organization_user: :user]
        ]
      ]
    )
  end
end
