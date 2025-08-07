defmodule DevhubWeb.Live.Settings.GitHubSettings do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Jobs.Import

  def mount(_params, _session, socket) do
    with {:ok, integration} <- Integrations.get_by(organization_id: socket.assigns.organization.id, provider: :github),
         {:ok, installation} <- GitHub.get_installation(socket.assigns.organization.id, integration.external_id) do
      socket
      |> assign(
        page_title: "Devhub",
        integration: integration,
        manage_link: installation["html_url"],
        settings: %{"ignore_usernames" => Enum.join(integration.settings["ignore_usernames"] || [], ",")},
        repositories: GitHub.list_repositories(socket.assigns.organization.id),
        import_status: "Starting import",
        import_percentage: 0,
        breadcrumbs: [
          %{title: "Integrations", path: ~p"/settings/integrations"},
          %{title: "GitHub"}
        ]
      )
      |> ok()
    else
      _error ->
        socket
        |> push_navigate(to: ~p"/settings/integrations/github/setup")
        |> ok()
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title="GitHub settings">
        <:actions>
          <.dropdown
            id="github-actions"
            trigger_click={
              JS.toggle_class("ring-blue-200 text-blue-600 bg-blue-50", to: "#actions-trigger")
              |> JS.toggle_class("rotate-180", to: "#actions-trigger > .hero-chevron-down")
            }
            trigger_click_away={
              JS.remove_class("ring-blue-200 text-blue-600 bg-blue-50", to: "#actions-trigger")
              |> JS.remove_class("rotate-180", to: "#actions-trigger > .hero-chevron-down")
            }
          >
            <:trigger>
              <div
                id="actions-trigger"
                class="bg-alpha-4 ring-alpha-24 flex w-56 items-center justify-between rounded px-3 py-2 text-sm ring-1 transition-all ease-in-out"
              >
                <div><span class="text-alpha-40 mr-1">Actions:</span> Select...</div>
                <.icon name="hero-chevron-down" class="size-4" />
              </div>
            </:trigger>
            <div class="divide-alpha-8 bg-surface-2 mt-2 w-56 divide-y rounded px-3 py-1 py-4 text-xs ring-1 ring-gray-100 ring-opacity-5">
              <div class="flex flex-col items-start gap-y-3 px-1">
                <button
                  phx-click={show_modal("sync-modal") |> JS.push("sync")}
                  class="group flex items-center gap-x-2"
                >
                  <.icon
                    name="hero-cloud-arrow-down"
                    class="size-4 text-gray-600 group-hover:text-gray-500"
                  />
                  <p class="text-gray-900 group-hover:text-gray-600">Sync</p>
                </button>
                <.link href={@manage_link} target="_blank" class="group flex items-center gap-x-2">
                  <.icon name="hero-cog" class="size-4 text-gray-600 group-hover:text-gray-500" />
                  <p class="text-gray-900 group-hover:text-gray-600">Manage GitHub installation</p>
                </.link>
                <button class="group flex items-center gap-x-2" phx-click="refresh_repositories">
                  <.icon
                    name="hero-arrow-path"
                    class="size-4 text-gray-600 group-hover:text-gray-500"
                  />
                  <p class="text-gray-900 group-hover:text-gray-600">Refresh linked repositories</p>
                </button>
              </div>
            </div>
          </.dropdown>
        </:actions>
      </.page_header>

      <.form :let={f} for={@settings} phx-change="update" class="bg-surface-1 rounded-lg p-4">
        <div class="grid grid-cols-1 gap-4 md:grid-cols-7">
          <div class="col-span-2">
            <h2 class="font-semibold text-gray-900">Integration settings</h2>
            <p class="text-alpha-64 mt-1 text-sm">
              This information allows you to define the configuration for GitHub data syncing.
            </p>
          </div>

          <div class="col-span-5 flex flex-col gap-y-4">
            <.input
              field={f[:ignore_usernames]}
              label="Github usernames to ignore (comma separated)"
              phx-debounce
            />
          </div>
        </div>
      </.form>

      <div class="bg-surface-1 mt-4 rounded-lg">
        <h1 class="p-4 text-xl font-bold">Repositories</h1>

        <table class="w-full whitespace-nowrap text-left">
          <colgroup>
            <col class="w-2/5" />
            <col class="w-2/5" />
            <col class="w-1/5" />
          </colgroup>
          <thead class="border-alpha-8 border-b text-sm">
            <tr>
              <th scope="col" class="p-4 font-bold uppercase">Repo</th>
              <th scope="col" class="p-4 font-bold uppercase">
                Enabled
              </th>
              <th scope="col" class="p-4 text-right font-bold uppercase">
                Latest Merge
              </th>
            </tr>
          </thead>
          <tbody class="divide-alpha-8 divide-y">
            <tr :for={repository <- @repositories}>
              <td class="p-4">
                <div class="flex items-center gap-x-4">
                  <div class="truncate">
                    {repository.name}
                  </div>
                </div>
              </td>
              <td class="p-4 text-sm text-gray-400">
                <button
                  phx-click="toggle_repository"
                  phx-value-id={repository.id}
                  type="button"
                  class="group relative inline-flex h-5 w-10 flex-shrink-0 cursor-pointer items-center justify-center rounded-full focus:outline-none"
                >
                  <span
                    aria-hidden="true"
                    class="pointer-events-none absolute h-full w-full rounded-md"
                  >
                  </span>
                  <span
                    aria-hidden="true"
                    class={[
                      "pointer-events-none absolute mx-auto h-4 w-9 rounded-full transition-colors duration-200 ease-in-out",
                      (repository.enabled && "bg-blue-300") || "bg-alpha-24"
                    ]}
                  >
                  </span>
                  <span
                    aria-hidden="true"
                    class={[
                      "pointer-events-none absolute left-0 inline-block h-5 w-5 transform rounded-full border border-gray-200 bg-white ring-0 transition-transform duration-200 ease-in-out",
                      (repository.enabled && "translate-x-5") || "translate-x-0"
                    ]}
                  >
                  </span>
                </button>
              </td>
              <td class="p-4 text-right text-sm text-gray-600">
                <format-date date={repository.pushed_at} format="date"></format-date>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <.modal id="sync-modal">
      <div class="relative">
        <div class="mb-6 text-center">
          <h3 class="text-base font-semibold text-gray-900">
            Syncing GitHub data
          </h3>
          <div class="mt-2">
            <p class="text-sm text-gray-500">
              You can close this modal and the sync will continue in the background.
            </p>
          </div>
          <button
            type="button"
            phx-click={JS.exec("data-cancel", to: "#sync-modal")}
            aria-label={gettext("close")}
            class="absolute -top-5 -right-4"
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </div>
      </div>

      <div :if={@import_percentage < 100}>
        <h4 class="sr-only">Status</h4>
        <div class="mt-4 flex items-center gap-x-1" data-testid="github-import-status">
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
        <div class="mt-4 flex items-center justify-between">
          <p class="text-alpha-64 text-sm font-medium">Your sync is complete</p>
          <.button
            type="button"
            variant="secondary"
            phx-click={JS.exec("data-cancel", to: "#sync-modal")}
            aria-label={gettext("close")}
          >
            Done
          </.button>
        </div>
      </div>
    </.modal>
    """
  end

  def handle_event("sync", _params, socket) do
    Phoenix.PubSub.subscribe(Devhub.PubSub, "github_sync:#{socket.assigns.organization.id}")

    %{organization_id: socket.assigns.organization.id, days_to_sync: 7}
    |> Import.new()
    |> Oban.insert()

    # sync 365 days with min priority
    %{organization_id: socket.assigns.organization.id, days_to_sync: 365}
    |> Import.new(priority: 9)
    |> Oban.insert!()

    socket |> put_flash(:info, "Syncing GitHub data") |> noreply()
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

    {:noreply, assign(socket, repositories: repositories)}
  end

  def handle_event("update", settings, socket) do
    settings = %{
      ignore_usernames: String.split(settings["ignore_usernames"], ",", trim: true)
    }

    Integrations.update(socket.assigns.integration, %{settings: settings})

    {:noreply, socket}
  end

  def handle_event("refresh_repositories", _params, socket) do
    GitHub.import_repositories(socket.assigns.integration)

    socket
    |> assign(repositories: GitHub.list_repositories(socket.assigns.organization.id))
    |> put_flash(:info, "All repositories imported")
    |> noreply()
  end

  def handle_info({:import_status, details}, socket) do
    socket |> assign(import_status: details.message, import_percentage: details.percentage) |> noreply()
  end
end
