defmodule Devhub.Portal do
  @moduledoc false

  @behaviour Devhub.Portal.Actions.Commits
  @behaviour Devhub.Portal.Actions.PRCounts
  @behaviour Devhub.Portal.Actions.ReviewedPRs

  alias Devhub.Portal.Actions

  @impl Actions.Commits
  defdelegate commits(organization_id, username, opts), to: Actions.Commits

  @impl Actions.PRCounts
  defdelegate pr_counts(organization_id, author, opts), to: Actions.PRCounts

  @impl Actions.ReviewedPRs
  defdelegate reviewed_prs(organization_id, author, opts), to: Actions.ReviewedPRs
end
