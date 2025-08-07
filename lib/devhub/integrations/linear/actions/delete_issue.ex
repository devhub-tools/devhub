defmodule Devhub.Integrations.Linear.Actions.DeleteIssue do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.Linear.Issue
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback delete_issue(Integration.t(), String.t()) :: {non_neg_integer(), nil | [term()]}
  def delete_issue(integration, external_id) do
    Repo.delete_all(
      from i in Issue,
        where: i.external_id == ^external_id and i.organization_id == ^integration.organization_id
    )
  end
end
