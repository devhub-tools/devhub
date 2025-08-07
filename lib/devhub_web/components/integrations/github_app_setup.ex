defmodule DevhubWeb.Components.Integrations.GitHubAppSetup do
  @moduledoc false
  use DevhubWeb, :html

  attr :org_slug, :string, required: true

  def github_app_setup(assigns) do
    name = Application.get_env(:devhub, DevhubWeb.Endpoint)[:url][:host] <> " (Devhub)"

    webhook_settings =
      if Devhub.prod?(),
        do: %{
          hook_attributes: %{
            url: DevhubWeb.Endpoint.url() <> "/webhook/github"
          },
          default_events: [
            "pull_request",
            "push",
            "repository",
            "pull_request_review"
          ]
        },
        else: %{}

    manifest =
      %{
        name: name,
        url: DevhubWeb.Endpoint.url(),
        redirect_url: DevhubWeb.Endpoint.url() <> "/github/setup-app",
        setup_url: DevhubWeb.Endpoint.url() <> "/github/setup-installation",
        public: false,
        default_permissions: %{contents: "write", checks: "write", pull_requests: "read", members: "read"}
      }
      |> Map.merge(webhook_settings)
      |> Jason.encode!()

    assigns =
      assign(assigns,
        manifest: manifest,
        register_url: "https://github.com/organizations/#{assigns.org_slug}/settings/apps/new",
        form: to_form(%{"org_slug" => assigns.org_slug})
      )

    ~H"""
    <div class="rounded-lg bg-blue-50 p-4">
      <div class="flex">
        <div class="shrink-0">
          <.icon name="hero-exclamation-circle-mini" class="size-5 text-blue-400" />
        </div>
        <div class="ml-3 flex flex-1 flex-col gap-y-2">
          <p class="text-sm/6 text-blue-700">
            This step will create a GitHub app on your organization. By registering your own GitHub app you can control the access to your repositories without exposing your data to any third party (including Devhub).
          </p>
          <p class="text-sm/6 text-blue-700">
            Your GitHub org slug is what appears in the GitHub URL. For example, for https://github.com/devhub-tools the slug is <span class="font-bold">devhub-tools</span>.
          </p>
        </div>
      </div>
    </div>
    <div class="bg-surface-1 mt-4 flex flex-col rounded-lg p-4">
      <.form
        :let={f}
        for={@form}
        phx-change="update_github_app_form"
        action={@register_url}
        method="post"
      >
        <div class="flex flex-col gap-y-3">
          <.input field={f[:org_slug]} type="text" label="GitHub org slug" />
        </div>

        <input type="hidden" name="manifest" id="manifest" value={@manifest} /><br />
        <.button type="submit" disabled={@org_slug == ""}>Register</.button>
      </.form>
    </div>
    """
  end
end
