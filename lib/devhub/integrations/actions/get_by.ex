defmodule Devhub.Integrations.Actions.GetBy do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback get_by(Keyword.t()) :: {:ok, Integration.t()} | {:error, :integration_not_found}
  def get_by(by) do
    Integration
    |> Repo.get_by(by)
    |> Repo.preload(:organization)
    |> case do
      %Integration{} = integration -> {:ok, integration}
      _not_found -> {:error, :integration_not_found}
    end
  end
end
