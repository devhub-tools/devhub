defmodule Devhub.Integrations.GitHub.Jobs.ImportTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Jobs.Import
  alias Devhub.Integrations.GitHub.Jobs.ImportRepository

  test "job completes successfully" do
    organization = insert(:organization)

    insert(:integration, organization: organization, provider: :github, external_id: "1")

    repository =
      insert(:repository, organization: organization, name: "devhub", owner: "devhub-tools", enabled: true)

    ignore_repository =
      insert(:repository, organization: organization, name: "ignore", owner: "devhub-tools", enabled: false)

    GitHub
    |> expect(:import_users, fn _integration ->
      :ok
    end)
    |> expect(:import_repositories, fn _integration ->
      :ok
    end)

    Import.perform(%Oban.Job{
      args: %{"organization_id" => organization.id},
      priority: 1
    })

    assert_enqueued worker: ImportRepository,
                    args: %{"repository_id" => repository.id, "index" => 0, "total" => 1},
                    priority: 1

    refute_enqueued worker: ImportRepository, args: %{"repository_id" => ignore_repository.id}
  end
end
