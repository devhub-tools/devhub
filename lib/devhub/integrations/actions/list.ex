defmodule Devhub.Integrations.Actions.List do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.Schemas.Ical
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback list(Integration.t()) :: [Integration.t() | Ical.t()]
  @callback list(Integration.t(), atom()) :: [Integration.t() | Ical.t()]
  def list(organization, type \\ :all) do
    fetch_integrations(organization, type)
  end

  defp fetch_integrations(organization, :all) do
    Repo.all(from i in Integration, where: i.organization_id == ^organization.id)
  end

  defp fetch_integrations(organization, :ical) do
    Repo.all(from i in Ical, where: i.organization_id == ^organization.id)
  end

  defp fetch_integrations(organization, type) do
    Repo.all(from i in Integration, where: i.organization_id == ^organization.id, where: i.provider == ^type)
  end
end
