defmodule Devhub.Users.Actions.UpdateOrganization do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Licensing.Client
  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization

  @callback update_organization(Organization.t(), map()) :: {:ok, Organization.t()} | {:error, Ecto.Changeset.t()}
  def update_organization(organization, attrs) do
    organization
    |> Organization.update_changeset(attrs)
    |> Repo.update()
    |> tap(fn result ->
      with {:ok, organization} <- result,
           %{"name" => _name} <- attrs do
        Client.update_installation(organization)
      end
    end)
  end
end
