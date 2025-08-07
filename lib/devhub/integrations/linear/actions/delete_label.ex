defmodule Devhub.Integrations.Linear.Actions.DeleteLabel do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.Linear.Label
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback delete_label(Integration.t(), String.t()) :: {non_neg_integer(), nil | [term()]}
  def delete_label(integration, external_id) do
    Repo.delete_all(
      from i in Label,
        where: i.external_id == ^external_id and i.organization_id == ^integration.organization_id
    )
  end
end
