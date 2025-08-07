defmodule Devhub.Integrations.GitHub.Actions.SetupCompleteTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub

  test "get_app/1" do
    organization = insert(:organization)

    refute GitHub.setup_complete?(organization)

    insert(:github_app, organization: organization)
    refute GitHub.setup_complete?(organization)

    insert(:integration, organization: organization, provider: :github)
    assert GitHub.setup_complete?(organization)
  end
end
