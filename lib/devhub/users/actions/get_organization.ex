defmodule Devhub.Users.Actions.GetOrganization do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Users.Actions.UpdateOrganization

  alias Devhub.Licensing.Client
  alias Devhub.QueryDesk
  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization

  @callback get_organization() :: Organization.t()
  def get_organization do
    {:ok, organization} =
      case Repo.all(Organization) do
        [%Organization{installation_id: nil} = organization] ->
          register_installation(organization)

        [%Organization{} = organization] ->
          {:ok, organization}

        [] ->
          initialize()

        _error ->
          raise "Multiple organizations not currently supported"
      end

    organization
  end

  @callback get_organization(Keyword.t()) :: {:ok, Organization.t()} | {:error, :organization_not_found}
  def get_organization(by) do
    case Repo.get_by(Organization, by) do
      %Organization{} = organization -> {:ok, organization}
      nil -> {:error, :organization_not_found}
    end
  end

  defp initialize do
    {:ok, organization} =
      Repo.transaction(fn ->
        {:ok, organization} =
          %{}
          |> Organization.create_changeset()
          |> Repo.insert!()
          |> register_installation()

        organization
      end)

    QueryDesk.setup_default_database(organization)

    {:ok, organization}
  end

  defp register_installation(%Organization{} = organization) do
    {public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)

    {:ok, installation_id} = Client.register_installation(organization, public_key)

    update_organization(organization, %{installation_id: installation_id, private_key: private_key})
  end
end
