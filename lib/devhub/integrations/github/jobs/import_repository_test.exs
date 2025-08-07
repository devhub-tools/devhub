defmodule Devhub.Integrations.GitHub.Jobs.ImportRepositoryTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Jobs.ImportRepository

  test "job completes successfully" do
    stub(GitHub, :get_app_token, fn _integration ->
      {:ok, Ecto.UUID.generate()}
    end)

    organization = insert(:organization)
    Phoenix.PubSub.subscribe(Devhub.PubSub, "github_sync:#{organization.id}")

    insert(:integration, organization: organization, provider: :github, external_id: "1")

    repository =
      insert(:repository, organization: organization, name: "devhub", owner: "devhub-tools", enabled: true)

    GitHub
    |> expect(:import_default_branch, fn _integration, _repository, _opts ->
      :ok
    end)
    |> expect(:import_pull_requests, fn _integration, _repository, _opts ->
      :ok
    end)

    ImportRepository.perform(%Oban.Job{
      args: %{"repository_id" => repository.id, "since" => "2024-01-01", "index" => 0, "total" => 1},
      priority: 0
    })

    assert_receive {:import_status, %{message: "Importing devhub-tools/devhub", percentage: +0.0}}
    assert_receive {:import_status, %{message: "Importing devhub-tools/devhub", percentage: 50.0}}
    assert_receive {:import_status, %{message: "Import done", percentage: 100}}
  end
end
