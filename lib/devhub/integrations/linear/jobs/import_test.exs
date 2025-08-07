defmodule Devhub.Integrations.Linear.Jobs.ImportTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear
  alias Devhub.Integrations.Linear.Jobs.Import

  test "job completes successfully" do
    access_token = Ecto.UUID.generate()

    integration =
      insert(:integration,
        provider: :linear,
        access_token: Jason.encode!(%{access_token: access_token})
      )

    Phoenix.PubSub.subscribe(Devhub.PubSub, "linear_sync:#{integration.organization_id}")

    Linear
    |> expect(:import_users, fn _integration ->
      assert_receive {:import_status, %{message: "Importing users", percentage: 0}}
      :ok
    end)
    |> expect(:import_projects, fn _integration, "-P30D" ->
      assert_receive {:import_status, %{message: "Importing projects", percentage: 25}}
      :ok
    end)
    |> expect(:import_labels, fn _integration ->
      assert_receive {:import_status, %{message: "Importing labels", percentage: 50}}
      :ok
    end)
    |> expect(:import_issues, fn _integration, "-P30D" ->
      assert_receive {:import_status, %{message: "Importing issues", percentage: 75}}
      :ok
    end)

    Import.perform(%Oban.Job{
      args: %{"id" => integration.id},
      priority: 0
    })

    assert_receive {:import_status, %{message: "Import done", percentage: 100}}
  end
end
