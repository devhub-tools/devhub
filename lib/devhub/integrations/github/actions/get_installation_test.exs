defmodule Devhub.Integrations.GitHub.Actions.GetInstallationTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub

  test "get_installation/2" do
    organization = insert(:organization)

    expect(GitHub, :get_app_token, fn _organization_id ->
      {:ok, "token"}
    end)

    expect(Tesla.Adapter.Finch, :call, fn %Tesla.Env{
                                            method: :get,
                                            url: "https://api.github.com/app/installations/59787994"
                                          },
                                          _opts ->
      TeslaHelper.response(
        body: %{
          "access_tokens_url" => "https://api.github.com/app/installations/59787994/access_tokens",
          "account" => %{
            "avatar_url" => "https://avatars.githubusercontent.com/u/174839376?v=4",
            "events_url" => "https://api.github.com/users/devhub-tools/events{/privacy}",
            "followers_url" => "https://api.github.com/users/devhub-tools/followers",
            "following_url" => "https://api.github.com/users/devhub-tools/following{/other_user}",
            "gists_url" => "https://api.github.com/users/devhub-tools/gists{/gist_id}",
            "gravatar_id" => "",
            "html_url" => "https://github.com/devhub-tools",
            "id" => 174_839_376,
            "login" => "devhub-tools",
            "node_id" => "O_kgDOCmvWUA",
            "organizations_url" => "https://api.github.com/users/devhub-tools/orgs",
            "received_events_url" => "https://api.github.com/users/devhub-tools/received_events",
            "repos_url" => "https://api.github.com/users/devhub-tools/repos",
            "site_admin" => false,
            "starred_url" => "https://api.github.com/users/devhub-tools/starred{/owner}{/repo}",
            "subscriptions_url" => "https://api.github.com/users/devhub-tools/subscriptions",
            "type" => "Organization",
            "url" => "https://api.github.com/users/devhub-tools",
            "user_view_type" => "public"
          },
          "app_id" => 1_116_770,
          "app_slug" => "localhost-1-devhub",
          "client_id" => "Iv23lilgLRNY9Gf437DY",
          "created_at" => "2025-01-19T18:36:23.000Z",
          "events" => ["pull_request", "pull_request_review", "push", "repository"],
          "has_multiple_single_files" => false,
          "html_url" => "https://github.com/organizations/devhub-tools/settings/installations/59787994",
          "id" => 59_787_994,
          "permissions" => %{
            "checks" => "write",
            "contents" => "write",
            "members" => "read",
            "metadata" => "read",
            "pull_requests" => "read"
          },
          "repositories_url" => "https://api.github.com/installation/repositories",
          "repository_selection" => "all",
          "single_file_name" => nil,
          "single_file_paths" => [],
          "suspended_at" => nil,
          "suspended_by" => nil,
          "target_id" => 174_839_376,
          "target_type" => "Organization",
          "updated_at" => "2025-01-19T18:36:23.000Z"
        }
      )
    end)

    assert {:ok,
            %{
              "html_url" => "https://github.com/organizations/devhub-tools/settings/installations/59787994",
              "account" => %{"login" => "devhub-tools"}
            }} =
             GitHub.get_installation(organization.id, "59787994")
  end
end
