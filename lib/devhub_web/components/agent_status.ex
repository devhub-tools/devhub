defmodule DevhubWeb.Components.AgentStatus do
  @moduledoc false
  use DevhubWeb, :html

  alias Devhub.Agents

  def agent_status(assigns) do
    ~H"""
    <%= if Agents.online?(@agent) do %>
      <div class="flex items-center rounded bg-green-200 px-2 py-1">
        <div class="mr-2 h-2 w-2 rounded-full bg-green-500"></div>
        <span class="text-sm text-green-800">Online</span>
      </div>
    <% else %>
      <div class="bg-alpha-8 flex items-center rounded px-2 py-1">
        <div class="mr-2 h-2 w-2 rounded-full bg-gray-400"></div>
        <span class="text-sm text-gray-900">Offline</span>
      </div>
    <% end %>
    """
  end
end
