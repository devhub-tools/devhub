defmodule DevhubWeb.Live.Coverbot.Dashboard do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Coverbot

  def mount(_params, _session, socket) do
    repositories = Coverbot.list_coverage(socket.assigns.organization)

    socket =
      Enum.reduce(repositories, socket, fn repository, socket ->
        data = Coverbot.coverage_data(repository.id)

        push_event(socket, "create_chart", %{
          id: repository.owner <> "-" <> repository.name <> "-coverage",
          type: "line",
          data: Enum.map(data, & &1.percentage),
          labels: Enum.map(data, &Timex.format!(&1.date, "{Mshort} {D}"))
        })
      end)

    socket
    |> assign(
      page_title: "Devhub",
      repositories: repositories
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header title="Code coverage">
        <:actions>
          <.link_button
            href="https://github.com/devhub-tools/coverbot-action"
            variant="text"
            target="_blank"
          >
            Setup instructions
          </.link_button>
        </:actions>
      </.page_header>

      <div>
        <.link
          :if={Enum.empty?(@repositories)}
          navigate={~p"/settings/api-keys"}
          class="border-alpha-16 relative block w-full rounded-lg border-2 border-dashed p-12 text-center hover:border-alpha-24 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          <.icon name="hero-code-bracket" class="text-alpha-64 mx-auto h-20 w-20" />
          <span class="mt-2 block text-sm text-gray-600">
            No coverage reported yet, create an api key to get started.
          </span>
        </.link>

        <div id="charts" phx-hook="Chart" class="grid grid-cols-1 gap-4 lg:grid-cols-2">
          <div :for={repository <- @repositories} class="bg-surface-1 ring-alpha-8 rounded-lg p-6">
            <div class="flex items-center justify-between">
              <div class="flex flex-col items-start">
                <p class="text-xl">
                  {repository.owner} / <span class="font-bold">{repository.name}</span>
                </p>

                <p class="text-alpha-64 mt-1 text-xs">
                  Default branch: {String.replace(repository.ref, "refs/heads/", "")}
                </p>
              </div>

              <div class="flex items-center gap-x-2">
                <.link_button navigate={~p"/coverbot/#{repository.id}"} variant="text">
                  View details
                </.link_button>
                <.link
                  target="_blank"
                  href={"https://img.shields.io/endpoint?url=#{URI.encode("#{DevhubWeb.Endpoint.url()}/coverbot/v1/#{repository.owner}/#{repository.name}/#{String.replace(repository.ref, "refs/heads/", "")}/badge.json")}"}
                >
                  <.shield_badge type={:coverage} percentage={repository.percentage} />
                </.link>
              </div>
            </div>

            <div class="mt-6 flex h-72">
              <div
                id={repository.owner <> "-" <> repository.name <> "-coverage-container"}
                class="w-full"
              >
                <canvas id={repository.owner <> "-" <> repository.name <> "-coverage"}></canvas>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
