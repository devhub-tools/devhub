defmodule DevhubWeb.Live.Coverbot.Repository do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Coverbot
  alias Devhub.Integrations.GitHub

  def mount(%{"repository_id" => repository_id}, _session, socket) do
    {:ok, repository} = GitHub.get_repository(id: repository_id, organization_id: socket.assigns.organization.id)
    {:ok, percentage} = Coverbot.coverage_percentage(repository, repository.default_branch)
    refs = Coverbot.list_repository_refs(repository_id: repository.id)

    socket
    |> assign(
      page_title: "Devhub",
      repository: repository,
      percentage: percentage,
      refs: refs,
      breadcrumbs: [
        %{title: "#{repository.owner}/#{repository.name}"}
      ]
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header title={@repository.owner <> "/" <> @repository.name}>
        <:actions>
          <.link
            target="_blank"
            href={"https://img.shields.io/endpoint?url=#{URI.encode("#{DevhubWeb.Endpoint.url()}/coverbot/v1/#{@repository.owner}/#{@repository.name}/#{@repository.default_branch}/badge.json")}"}
          >
            <.shield_badge type={:coverage} percentage={@percentage} />
          </.link>
        </:actions>
      </.page_header>
      <ul role="list" class="divide-alpha-8 bg-surface-1 divide-y rounded-lg">
        <li :for={ref <- @refs} class="hover:bg-alpha-4">
          <.link
            navigate={~p"/coverbot/coverage/#{ref.id}"}
            class="relative flex w-full items-center justify-between gap-x-6 p-4"
          >
            <div class="flex min-w-0 gap-x-4">
              <div class="min-w-0 flex-auto">
                <p class="text-sm font-bold">
                  {ref.ref}
                </p>
                <p class="mt-1 flex text-xs text-gray-500">
                  {ref.sha}
                </p>
              </div>
            </div>
            <div class="flex gap-x-2">
              <div class="flex shrink-0 items-center gap-x-4 text-gray-800">
                {ref.percentage}%
              </div>
              <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                <.icon name="hero-chevron-right-mini" />
              </div>
            </div>
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
