defmodule Devhub.Integrations.GitHub.Actions.SetupComplete do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.Schemas.GitHubApp
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization

  @callback setup_complete?(Organization.t()) :: boolean()
  def setup_complete?(organization) do
    github_app = from a in GitHubApp, where: [organization_id: ^organization.id]
    integration = from i in Integration, where: [organization_id: ^organization.id, provider: :github]

    Repo.exists?(github_app) && Repo.exists?(integration)
  end
end
