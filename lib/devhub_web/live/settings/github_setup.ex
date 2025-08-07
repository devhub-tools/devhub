defmodule DevhubWeb.Live.Settings.GitHubSetup do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Jobs.Import

  def mount(_params, _session, socket) do
    app =
      case GitHub.get_app(organization_id: socket.assigns.organization.id) do
        {:ok, app} -> app
        {:error, _error} -> nil
      end

    github_integration =
      case Integrations.get_by(organization_id: socket.assigns.organization.id, provider: :github) do
        {:ok, integration} -> integration
        {:error, :integration_not_found} -> nil
      end

    repositories = GitHub.list_repositories(socket.assigns.organization.id)

    socket
    |> assign(
      page_title: "Devhub",
      app: app,
      github_integration: github_integration,
      org_slug: "",
      repositories: repositories,
      import_status: "Starting import",
      import_percentage: 0,
      import_started: false,
      breadcrumbs: [
        %{title: "Settings", path: ~p"/settings/integrations"},
        %{title: "GitHub setup"}
      ]
    )
    |> ok()
  end

  def render(%{app: nil} = assigns) do
    ~H"""
    <div>
      <.page_header title="GitHub setup" subtitle="Register a GitHub app to sync your data" />
      <.github_app_setup org_slug={@org_slug} />
    </div>
    """
  end

  def render(%{github_integration: nil} = assigns) do
    ~H"""
    <div>
      <.page_header title="GitHub setup" subtitle="Connect your repositories to your registered app" />
      <div class="rounded-lg bg-blue-50 p-4">
        <div class="flex">
          <div class="shrink-0">
            <.icon name="hero-exclamation-circle-mini" class="size-5 text-blue-400" />
          </div>
          <div class="ml-2 flex flex-1 flex-col gap-y-2">
            <p class="text-sm/6 text-blue-700">
              Your GitHub app has been created and now it needs to be installed on your organization for Devhub to start syncing data.
            </p>
          </div>
        </div>
      </div>
      <.link
        href={"https://github.com/apps/#{@app.slug}/installations/new"}
        class="ring-alpha-16 mt-4 flex w-full items-center justify-center gap-2 rounded-md py-3 text-sm font-semibold ring-1 ring-inset hover:bg-alpha-4 focus-visible:ring-transparent"
      >
        <svg class="size-5 fill-gray-900" fill="currentColor" viewBox="0 0 20 20" aria-hidden="true">
          <path
            fill-rule="evenodd"
            d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z"
            clip-rule="evenodd"
          />
        </svg>
        <span class="text-sm/6 font-semibold">Connect</span>
      </.link>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title="GitHub setup" subtitle="Connect your repositories to your registered app">
        <:actions>
          <.button
            :if={not Enum.empty?(@repositories) and not @import_started}
            phx-click="start_import"
            class="ml-2"
          >
            Import
          </.button>
        </:actions>
      </.page_header>
      <div class="bg-surface-1 rounded-lg p-4">
        <.table
          :if={not Enum.empty?(@repositories) and not @import_started}
          id="repositories"
          rows={@repositories}
        >
          <:col :let={repo} label="Name">
            <div class="flex items-center justify-between">
              {"#{repo.owner}/#{repo.name}"}
              <.toggle_button
                phx-click="toggle_repository"
                phx-value-id={repo.id}
                enabled={repo.enabled}
              />
            </div>
          </:col>
        </.table>

        <div :if={@import_started and @import_percentage < 100}>
          <h4 class="sr-only">Status</h4>
          <div class="flex items-center gap-x-1" data-testid="github-import-status">
            <div class="size-4 ml-1"><.spinner /></div>
            <p class="text-alpha-64 text-sm font-medium">{@import_status}</p>
          </div>
          <div class="mt-3" aria-hidden="true">
            <div class="overflow-hidden rounded-full bg-gray-200">
              <div
                class="h-2 rounded-full bg-blue-600 transition-all duration-1000"
                data-testid="github-import-percentage"
                style={"width: #{@import_percentage}%"}
              >
              </div>
            </div>
          </div>
        </div>

        <div :if={@import_percentage == 100}>
          <h4 class="sr-only">Status</h4>
          <div class="flex items-center justify-between">
            <p class="text-alpha-64 text-sm font-medium">Your import is complete</p>
            <.link_button navigate={~p"/settings/integrations/github"}>
              Done
            </.link_button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("update_github_app_form", params, socket) do
    socket |> assign(org_slug: params["org_slug"]) |> noreply()
  end

  def handle_event("toggle_repository", %{"id" => id}, socket) do
    repositories =
      Enum.map(socket.assigns.repositories, fn repository ->
        if repository.id == id do
          {:ok, repository} =
            GitHub.update_repository(repository, %{enabled: !repository.enabled})

          repository
        else
          repository
        end
      end)

    socket |> assign(repositories: repositories) |> noreply()
  end

  def handle_event("start_import", _params, socket) do
    Phoenix.PubSub.subscribe(Devhub.PubSub, "github_sync:#{socket.assigns.organization.id}")

    # sync 7 days quickly to provide feedback to user
    %{organization_id: socket.assigns.organization.id, days_to_sync: 7}
    |> Import.new()
    |> Oban.insert!()

    # sync 90 days with less priority
    %{organization_id: socket.assigns.organization.id, days_to_sync: 90}
    |> Import.new(priority: 1)
    |> Oban.insert!()

    # sync 365 days with min priority
    %{organization_id: socket.assigns.organization.id, days_to_sync: 365}
    |> Import.new(priority: 9)
    |> Oban.insert!()

    socket |> assign(import_started: true) |> noreply()
  end

  def handle_info({:import_status, details}, socket) do
    socket |> assign(import_status: details.message, import_percentage: details.percentage) |> noreply()
  end
end
