defmodule DevhubWeb.Plugs.HandleGitHubWebhookTest do
  use DevhubWeb.ConnCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.TerraDesk

  test "push event", %{conn: conn, organization: organization} do
    app = insert(:github_app, organization: organization)
    repository = insert(:repository, organization: organization, owner: "devhub-tools", name: "devhub")

    insert(:integration,
      organization: organization,
      provider: :github,
      external_id: "48540037"
    )

    # the push event should only affect the devhub_web workspace
    devhub_web =
      insert(:workspace,
        organization: organization,
        repository: repository,
        path: "lib/devhub_web/"
      )

    _devhub =
      insert(:workspace,
        organization: organization,
        repository: repository,
        path: "lib/devhub/"
      )

    expect(TerraDesk, :create_plan, fn workspace,
                                       "main",
                                       [commit_sha: "892638c0bc221bc2a31abc161560977f5fcbc73a", run: true] ->
      assert workspace.id == devhub_web.id
      {:ok, build(:plan, workspace: workspace)}
    end)

    # only allow calling create_plan once
    reject(&TerraDesk.create_plan/2)

    body = File.read!("test/support/github/push.json")

    assert conn
           |> put_req_header("content-type", "application/json")
           |> put_req_header("x-github-hook-installation-target-id", to_string(app.external_id))
           |> put_req_header(
             "x-hub-signature-256",
             "sha256=02db17eb0e3a0d05fc6c0a7a4be2a0b5869d80a9911ca86139b4f62301673490"
           )
           |> post("/webhook/github", body)
           |> response(200)
  end

  test "terradesk sync event", %{conn: conn, organization: organization} do
    app = insert(:github_app, organization: organization)
    repository = insert(:repository, organization: organization, owner: "devhub-tools", name: "devhub")

    insert(:integration,
      organization: organization,
      provider: :github,
      external_id: "48540037"
    )

    # the push event should only affect the devhub_web workspace
    devhub_web =
      insert(:workspace,
        organization: organization,
        repository: repository,
        path: "lib/devhub_web/"
      )

    _devhub =
      insert(:workspace,
        organization: organization,
        repository: repository,
        path: "lib/devhub/"
      )

    expect(TerraDesk, :create_plan, fn workspace,
                                       "dh-362-ai-chat-improvements",
                                       [commit_sha: "710e2199da60f69a3a11ce5b7bdaae1723686388"] ->
      assert workspace.id == devhub_web.id
      {:ok, build(:plan, workspace: workspace)}
    end)

    # only allow calling create_plan once
    reject(&TerraDesk.create_plan/2)

    GitHub.Client
    |> expect(:compare, 2, fn _integration, _repository, "main", "dh-362-ai-chat-improvements" ->
      TeslaHelper.response(body: %{"files" => [%{"filename" => "lib/devhub_web/plugs/handle_github_webhook.ex"}]})
    end)
    |> expect(:create_check, 2, fn _integration, _repository, _details ->
      TeslaHelper.response([])
    end)

    body = File.read!("test/support/github/terradesk-sync.json")

    assert conn
           |> put_req_header("content-type", "application/json")
           |> put_req_header("x-github-hook-installation-target-id", to_string(app.external_id))
           |> put_req_header(
             "x-hub-signature-256",
             "sha256=fe464281fe80de675bae44cc4c2a32e6bebb4563eec5ba60c82520c8a6a88e3c"
           )
           |> post("/webhook/github", body)
           |> response(200)
  end

  test "metrics sync event", %{conn: conn, organization: organization} do
    app = insert(:github_app, organization: organization)

    insert(:integration,
      organization: organization,
      provider: :github,
      external_id: "48540037"
    )

    app_token = Ecto.UUID.generate()
    app_auth_header = {"authorization", "Bearer #{app_token}"}

    installation_token = Ecto.UUID.generate()
    installation_auth_header = {"authorization", "Bearer #{installation_token}"}

    expect(GitHub, :get_app_token, fn _integration ->
      {:ok, app_token}
    end)

    Tesla.Adapter.Finch
    |> expect(:call, fn %Tesla.Env{
                          url: url,
                          query: [],
                          headers: [
                            ^app_auth_header,
                            {"traceparent", _traceparent},
                            {"accept", "application/vnd.github.v3+json"},
                            {"x-github-api-version", "2022-11-28"},
                            {"user-agent", "Devhub"},
                            {"content-type", "application/json"}
                          ],
                          body: "{}"
                        },
                        _opts ->
      assert url == "https://api.github.com/app/installations/48540037/access_tokens"
      TeslaHelper.response(status: 200, body: %{"token" => installation_token})
    end)
    |> expect(:call, fn %Tesla.Env{
                          url: url,
                          query: [],
                          headers: [
                            ^installation_auth_header,
                            {"traceparent", _traceparent},
                            {"accept", "application/vnd.github.v3+json"},
                            {"x-github-api-version", "2022-11-28"},
                            {"user-agent", "Devhub"},
                            {"content-type", "application/json"}
                          ],
                          body: body
                        },
                        _opts ->
      assert url == "https://api.github.com/graphql"
      assert String.contains?(body, "pullRequest")

      TeslaHelper.response(
        status: 200,
        body: %{
          "data" => %{
            "repository" => %{
              "pullRequest" => %{
                "commits" => %{
                  "nodes" => [
                    %{"commit" => %{"authoredDate" => "2024-05-15T16:37:47Z"}}
                  ]
                },
                "reviews" => %{
                  "nodes" => [
                    %{
                      "id" => "PRR_kwDOEHp2wc6OgAso",
                      "author" => %{"login" => "michaelst"},
                      "createdAt" => "2024-05-22T21:49:05Z"
                    }
                  ]
                },
                "timelineItems" => %{
                  "nodes" => [
                    %{
                      "createdAt" => "2024-05-22T21:49:05Z"
                    }
                  ]
                }
              }
            }
          }
        }
      )
    end)

    body = File.read!("test/support/github/metrics-sync.json")

    assert conn
           |> put_req_header("content-type", "application/json")
           |> put_req_header("x-github-hook-installation-target-id", to_string(app.external_id))
           |> put_req_header(
             "x-hub-signature-256",
             "sha256=49ac9a4f9f3ba894a545e15e0b2e4af1e76c65d7896cd4b7be39a02554f5ae6a"
           )
           |> post("/webhook/github", body)
           |> response(200)
  end

  test "missing github app", %{conn: conn} do
    body = File.read!("test/support/github/metrics-sync.json")

    assert conn
           |> put_req_header("content-type", "application/json")
           |> put_req_header("x-github-hook-installation-target-id", "123")
           |> put_req_header(
             "x-hub-signature-256",
             "sha256=88a1b773039295274af8c462df24fece5ec9af47f484e15a2ffcab3c6bf97b0e"
           )
           |> post("/webhook/github", body)
           |> response(200)
  end

  test "rejects invalid signature", %{conn: conn, organization: organization} do
    app = insert(:github_app, organization: organization)

    body = File.read!("test/support/github/metrics-sync.json")

    assert conn
           |> put_req_header("content-type", "application/json")
           |> put_req_header("x-github-hook-installation-target-id", to_string(app.external_id))
           |> put_req_header(
             "x-hub-signature-256",
             "sha256=88a1b773039295274af8c462df24fece5ec9af47f484e15a2ffcab3c6bf97b0e"
           )
           |> post("/webhook/github", body)
           |> response(403)
  end
end
