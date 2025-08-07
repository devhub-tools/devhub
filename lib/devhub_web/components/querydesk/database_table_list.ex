defmodule DevhubWeb.Components.DatabaseTableList do
  @moduledoc false
  use DevhubWeb, :html

  def database_table_list(assigns) do
    ~H"""
    <div class="px-4">
      <.back navigate={~p"/querydesk"}>
        Database list
      </.back>
      <ul class="-mx-2 space-y-1 pt-2">
        <li>
          <.link
            :if={@organization_user.permissions.super_admin}
            href={~p"/querydesk/databases/#{@database.id}"}
            target="_blank"
            class="flex items-center rounded-lg p-2 font-normal hover:bg-alpha-4"
          >
            <.icon name="hero-cog-6-tooth" class="size-5 text-gray-400" />
            <span class="ml-2 flex-1 whitespace-nowrap text-sm">Settings</span>
          </.link>
        </li>
        <li>
          <.link
            navigate={~p"/querydesk/databases/#{@database.id}/query"}
            class="flex items-center rounded-lg p-2 font-normal hover:bg-alpha-4"
          >
            <.icon name="hero-command-line" class="size-5 text-gray-400" />
            <span class="ml-2 flex-1 whitespace-nowrap text-sm">Query view</span>
          </.link>
        </li>
        <li>
          <.link
            :if={Code.ensure_loaded?(DevhubPrivateWeb.Live.QueryDesk.PendingQueries)}
            href="/querydesk/pending-queries"
            target="_blank"
            class="flex items-center rounded-lg p-2 font-normal hover:bg-alpha-4"
          >
            <.icon name="hero-check-badge" class="size-5 text-gray-400" />
            <span class="ml-2 flex-1 whitespace-nowrap text-sm">Pending queries</span>
          </.link>
        </li>
        <li
          :if={@database.adapter == :postgres && System.get_env("PROXY_COMMAND")}
          phx-click={show_modal("proxy")}
          class="cursor-pointer"
        >
          <div class="flex items-center rounded-lg p-2 font-normal hover:bg-alpha-4">
            <.icon name="hero-bolt" class="size-5 text-gray-400" />
            <span class="ml-2 flex-1 whitespace-nowrap text-sm">Proxy</span>
          </div>
        </li>
        <li>
          <.link
            navigate={~p"/querydesk/databases/#{@database.id}/library"}
            class="flex items-center rounded-lg p-2 font-normal hover:bg-alpha-4"
          >
            <.icon name="hero-book-open" class="size-5 text-gray-400" />
            <span class="ml-2 flex-1 whitespace-nowrap text-sm">Library</span>
          </.link>
        </li>
        <li>
          <.link
            navigate={~p"/querydesk/databases/#{@database.id}/history"}
            class="flex items-center rounded-lg p-2 font-normal hover:bg-alpha-4"
          >
            <.icon name="hero-clock" class="size-5 text-gray-400" />
            <span class="ml-2 flex-1 whitespace-nowrap text-sm">History</span>
          </.link>
        </li>
        <li>
          <.link
            navigate={~p"/querydesk/databases/#{@database.id}/ai"}
            class="flex items-center rounded-lg p-2 font-normal hover:bg-alpha-4"
          >
            <.icon name="hero-chat-bubble-left-right" class="size-5 text-gray-400" />
            <span class="ml-2 flex-1 whitespace-nowrap text-sm">AI assistant</span>
          </.link>
        </li>

        <hr class="border-alpha-4 border-0 border-b" />

        <%= for table <- @tables do %>
          <li id={table <> "-list-item"} phx-hook={@selected == table && "ScrollToItem"}>
            <.link
              navigate={~p"/querydesk/databases/#{@database.id}/table/#{table}"}
              class={[
                "hover:bg-alpha-4",
                "flex",
                "font-normal",
                "items-center",
                "p-1.5",
                "rounded",
                @selected == table && "bg-alpha-4"
              ]}
            >
              <div class="min-w-fit">
                <.icon name="hero-table-cells" class="size-5 text-gray-400" />
              </div>
              <span class="ml-3 flex-1 truncate whitespace-nowrap text-sm">{table}</span>
            </.link>
          </li>
        <% end %>
      </ul>
    </div>
    <.proxy_modal
      database={@database}
      user={@user}
      organization_user={@organization_user}
      proxy_password={@proxy_password}
    />
    """
  end

  defp proxy_modal(assigns) do
    ~H"""
    <.modal id="proxy" size="medium">
      <div class="mb-4 rounded-md bg-blue-200 p-4">
        <div class="flex">
          <div class="shrink-0">
            <.icon name="hero-information-circle" class="size-5 text-blue-800" />
          </div>
          <div class="ml-2">
            <h3 class="text-sm font-medium text-blue-800">
              If using DataGrip turn on `single database mode` in your connection options.
            </h3>
          </div>
        </div>
      </div>
      <div>To connect to proxy with your own client:</div>

      <div :if={System.get_env("PROXY_INSTRUCTIONS")} class="text-alpha-64 mt-3">
        {System.get_env("PROXY_INSTRUCTIONS")}
      </div>
      <div class="bg-surface-3 mt-2 flex items-center justify-between rounded p-4">
        <div class="mr-2 overflow-x-scroll">
          <code class="break-all">
            {System.get_env("PROXY_COMMAND")}
          </code>
        </div>
        <copy-button value={System.get_env("PROXY_COMMAND")} />
      </div>
      <div class="text-alpha-64 mt-4 text-sm uppercase">Database:</div>
      <div class="bg-surface-3 mt-2 flex items-center justify-between rounded p-4">
        <div class="mr-2 overflow-x-scroll">
          <code class="break-all">
            <div><span :if={@database.group}>{@database.group}:</span>{@database.name}</div>
          </code>
        </div>
        <copy-button value={
          if @database.group,
            do: @database.group <> ":" <> @database.name,
            else: @database.name
        } />
      </div>
      <div class="text-alpha-64 mt-4 text-sm uppercase">Username:</div>
      <div class="bg-surface-3 mt-2 flex items-center justify-between rounded p-4">
        <div class="mr-2 overflow-x-scroll">
          <code class="break-all">
            <div>{@user.email}</div>
          </code>
        </div>
        <copy-button value={@user.email} />
      </div>
      <div class="text-alpha-64 mt-4 text-sm uppercase">Password:</div>
      <div
        :if={@proxy_password}
        class="bg-surface-3 mt-2 flex items-center justify-between rounded p-4"
      >
        <div class="mr-2 overflow-x-scroll">
          <code class="break-all">
            {@proxy_password}
          </code>
        </div>
        <copy-button value={@proxy_password} />
      </div>
      <.button :if={is_nil(@proxy_password)} phx-click="generate_proxy_password" class="mt-2">
        Generate
      </.button>
    </.modal>
    """
  end
end
