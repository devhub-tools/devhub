defmodule Devhub.ApiKeys.Actions.List do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.ApiKeys.Schemas.ApiKey
  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization

  @callback list(Organization.t()) :: [ApiKey.t()]
  def list(organization) do
    query =
      from a in ApiKey,
        where: a.organization_id == ^organization.id,
        where: is_nil(a.expires_at) or a.expires_at > ^DateTime.utc_now()

    Repo.all(query)
  end
end
