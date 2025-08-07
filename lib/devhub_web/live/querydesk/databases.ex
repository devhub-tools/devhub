defmodule DevhubWeb.Live.QueryDesk.Databases do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.QueryDesk

  def mount(_params, _session, socket) do
    databases = QueryDesk.list_databases(socket.assigns.organization_user)

    socket
    |> assign(
      page_title: "Devhub",
      databases: databases
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div id="querydesk">
      <.page_header title="Databases">
        <:actions>
          <.link_button
            :if={@permissions.super_admin}
            type="button"
            navigate={~p"/querydesk/databases/new"}
          >
            New database
          </.link_button>
        </:actions>
      </.page_header>

      <div class="bg-surface-1 rounded-lg">
        <div>
          <.database_list
            databases={Enum.filter(@databases, &(not Enum.empty?(&1.user_pins)))}
            permissions={@permissions}
          />
        </div>

        <.database_list
          databases={Enum.filter(@databases, &(is_nil(&1.group) and Enum.empty?(&1.user_pins)))}
          permissions={@permissions}
        />
        <div class="divide-alpha-8 divide-y">
          <div
            :for={
              {group, databases} <-
                @databases
                |> Enum.group_by(& &1.group)
            }
            class="divide-alpha-8 divide-y"
          >
            <.details :if={not is_nil(group)} id={String.replace(group, " ", "-")} class="w-full">
              <:summary>
                <div class="flex h-20 items-center justify-between px-4 hover:bg-alpha-4">
                  <div>{group}</div>
                  <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                    <.icon name="hero-chevron-down-mini" />
                  </div>
                </div>
              </:summary>

              <.database_list databases={databases} permissions={@permissions} />
            </.details>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("toggle_pin", %{"database_id" => database_id}, socket) do
    organization_user = socket.assigns.organization_user

    case Enum.find(socket.assigns.databases, &(&1.id == database_id)) do
      %{user_pins: []} = database ->
        {:ok, pinned_database} = QueryDesk.pin_database(organization_user, database)

        databases =
          Enum.map(socket.assigns.databases, fn database ->
            if database.id == pinned_database.database_id do
              %{database | user_pins: [pinned_database]}
            else
              database
            end
          end)

        {:noreply, assign(socket, databases: databases)}

      %{user_pins: [pinned_database]} ->
        {:ok, pinned_database} = QueryDesk.unpin_database(pinned_database)

        databases =
          Enum.map(socket.assigns.databases, fn database ->
            if database.id == pinned_database.database_id do
              %{database | user_pins: []}
            else
              database
            end
          end)

        {:noreply, assign(socket, databases: databases)}
    end
  end

  defp database_list(assigns) do
    ~H"""
    <ul role="list" class="divide-alpha-8 divide-y">
      <li
        :for={
          database <-
            Enum.sort_by(@databases, fn db ->
              {Enum.empty?(db.user_pins), String.downcase(db.name || "")}
            end)
        }
        class="px-4 hover:bg-alpha-4"
      >
        <div class="flex items-center">
          <div class="flex min-w-0 flex-1 items-center justify-between gap-x-4">
            <button
              phx-click="toggle_pin"
              phx-value-database_id={database.id}
              class="justify-content flex items-center"
            >
              <.icon
                name={if Enum.empty?(database.user_pins), do: "hero-star", else: "hero-star-solid"}
                class={[
                  "size-5 hover:bg-yellow-400",
                  if(Enum.empty?(database.user_pins), do: "bg-gray-500", else: "bg-yellow-500")
                ]}
              />
            </button>
            <.link
              :if={@permissions.super_admin}
              navigate={~p"/querydesk/databases/#{database.id}"}
              class="block text-sm text-gray-700"
            >
              <.icon name="hero-cog-6-tooth" class="size-5" />
            </.link>

            <.link
              navigate={~p"/querydesk/databases/#{database.id}/query"}
              class="flex h-20 w-full items-center justify-between"
            >
              <div class="truncate">
                <div class="flex items-center gap-x-2 text-sm font-bold">
                  <div>{database.name || "(New database)"}</div>
                  <div :if={database.group} class="flex items-center rounded bg-blue-200 px-2 py-1">
                    <span class="text-xs text-blue-900">{database.group}</span>
                  </div>
                </div>
                <div class="mt-1 flex flex-col">
                  <p class="truncate text-left text-xs text-gray-600">
                    <span class="text-alpha-64">database:</span> {database.database} ({database.adapter})
                  </p>
                </div>
              </div>

              <div class="mt-4 flex-shrink-0 sm:mt-0 sm:ml-5">
                <div class="flex items-center -space-x-1 space-x-4 overflow-hidden">
                  <.button variant="outline">Connect</.button>
                </div>
              </div>
            </.link>
          </div>
        </div>
      </li>
    </ul>
    """
  end
end
