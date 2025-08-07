defmodule DevhubWeb.Live.Settings.Agents do
  @moduledoc false
  use DevhubWeb, :live_view

  import DevhubWeb.Components.SettingsTabs

  alias Devhub.Agents

  def mount(_params, _session, socket) do
    agents = Agents.list(socket.assigns.organization.id)

    socket
    |> assign(
      page_title: "Devhub",
      agents: agents
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header>
        <:header>
          <.settings_tabs active_path={@active_path} organization_user={@organization_user} />
        </:header>
        <:actions>
          <.button type="button" phx-click={show_modal("add-agent")}>
            Add agent
          </.button>
        </:actions>
      </.page_header>

      <ul role="list" class="divide-alpha-8 bg-surface-1 divide-y rounded-lg">
        <li :for={agent <- @agents} class="flex items-center justify-between gap-x-6 p-4">
          <div>
            <p class="font-bold">{agent.name}</p>
            <p class="mt-1 text-sm text-gray-600">{agent.id}</p>
          </div>
          <div class="flex items-center gap-x-12">
            <.agent_status agent={agent} />
            <.dropdown id={"agent-#{agent.id}-options"}>
              <:trigger>
                <div class="bg-alpha-4 rounded-md p-2">
                  <.icon name="hero-ellipsis-vertical" class="text-gray-900" />
                </div>
              </:trigger>
              <div class="divide-alpha-8 bg-surface-2 absolute top-2 -right-10 w-48 divide-y rounded px-4 py-3 ring-1 ring-gray-100 ring-opacity-5">
                <div class="px-4 py-3">
                  <.link href={~p"/agents/#{agent.id}/config"} class="mb-1 text-sm">
                    Download Config
                  </.link>
                </div>
                <div
                  class="cursor-pointer px-4 py-3"
                  phx-click={show_modal("update-agent-#{agent.id}")}
                >
                  <p class="mb-1 text-sm">Edit</p>
                </div>
              </div>
            </.dropdown>
          </div>
          <.modal id={"update-agent-#{agent.id}"}>
            <div>
              <div class="mb-2 text-center">
                <h3 class="text-base font-semibold text-gray-900">
                  Update agent
                </h3>
              </div>
            </div>
            <.form
              for={%{}}
              phx-submit={JS.push("update_agent") |> hide_modal("update-agent-#{agent.id}")}
              data-testid="update_agent"
            >
              <input type="hidden" name="agent_id" value={agent.id} />
              <.input label="Name" name="name" value={agent.name} />
              <div class="mt-4 grid grid-cols-2 gap-4">
                <.button
                  type="button"
                  variant="secondary"
                  phx-click={JS.exec("data-cancel", to: "#update-agent-#{agent.id}")}
                  aria-label={gettext("close")}
                >
                  Cancel
                </.button>
                <.button type="submit" variant="primary">Save</.button>
              </div>
            </.form>
          </.modal>
        </li>
      </ul>

      <.modal id="add-agent">
        <div>
          <div class="mb-6 text-center">
            <h3 class="text-base font-semibold text-gray-900">
              Create a new agent
            </h3>
            <div class="mt-2">
              <p class="text-sm text-gray-500">
                Once created you can download the agent config from the list view.
              </p>
            </div>
          </div>
        </div>
        <.form
          for={%{}}
          phx-submit={JS.push("add_agent") |> hide_modal("add-agent")}
          data-testid="add_agent"
        >
          <.input label="Name" name="name" value="" />
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#add-agent")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit" variant="primary">Save</.button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  def handle_event("add_agent", %{"name" => name}, socket) do
    {:ok, agent} = Agents.create(name, socket.assigns.organization)
    agents = Enum.sort_by([agent | socket.assigns.agents], & &1.name)

    {:noreply, assign(socket, agents: agents)}
  end

  def handle_event("update_agent", params, socket) do
    index = Enum.find_index(socket.assigns.agents, &(&1.id == params["agent_id"]))
    agent = Enum.at(socket.assigns.agents, index)
    {:ok, agent} = Agents.update(agent, params)
    agents = List.replace_at(socket.assigns.agents, index, agent)

    {:noreply, assign(socket, agents: agents)}
  end
end
