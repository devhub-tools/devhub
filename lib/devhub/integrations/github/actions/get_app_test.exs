defmodule Devhub.Integrations.GitHub.Actions.GetAppTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Schemas.GitHubApp

  test "get_app/1" do
    organization = insert(:organization)

    assert {:error, :github_app_not_found} = GitHub.get_app(organization_id: organization.id)

    insert(:github_app, organization: organization)

    assert {:ok, %GitHubApp{}} = GitHub.get_app(organization_id: organization.id)
  end
end
