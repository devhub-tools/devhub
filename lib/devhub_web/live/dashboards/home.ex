defmodule DevhubWeb.Live.Dashboards.Home do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Dashboards
  alias Devhub.Permissions

  def mount(_params, _session, socket) do
    dashboards = Dashboards.list_dashboards(socket.assigns.organization_user)

    socket
    |> assign(
      page_title: "Devhub",
      dashboards: dashboards
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header title="Dashboards">
        <:actions>
          <.button
            :if={Permissions.can?(:manage_dashboards, @organization_user)}
            data-testid="add-dashboard-button"
            phx-click={show_modal("add-dashboard")}
          >
            Add dashboard
          </.button>
        </:actions>
      </.page_header>

      <div
        :if={Enum.empty?(@dashboards)}
        class="border-alpha-16 rounded-lg border-2 border-dashed p-12 text-center"
      >
        <.icon name="hero-chart-bar" class="size-12 mx-auto text-gray-500" />
        <h3 class="mt-2 text-sm font-semibold text-gray-900">No dashboards</h3>
      </div>

      <.dashboard_list dashboards={@dashboards} organization_user={@organization_user} />

      <.modal id="add-dashboard">
        <.form
          for={%{}}
          phx-submit={JS.push("add_dashboard") |> hide_modal("add-dashboard")}
          data-testid="add-dashboard-form"
        >
          <.input label="Dashboard name" name="name" value="" />
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#add-dashboard")}
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

  def handle_event("add_dashboard", %{"name" => name}, socket) do
    case Dashboards.create_dashboard(%{name: name, organization_id: socket.assigns.organization.id}) do
      {:ok, dashboard} ->
        socket |> push_navigate(to: ~p"/dashboards/#{dashboard.id}") |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to create dashboard") |> noreply()
    end
  end

  defp dashboard_list(assigns) do
    ~H"""
    <ul role="list" class="divide-alpha-16 bg-surface-1 divide-y rounded-lg">
      <li :for={dashboard <- @dashboards} class="hover:bg-alpha-4">
        <div class="flex items-center">
          <div class="flex min-w-0 flex-1 items-center justify-between">
            <.link
              :if={Permissions.can?(:manage_dashboards, @organization_user)}
              navigate={~p"/dashboards/#{dashboard.id}"}
              class="ml-4 block text-sm text-gray-700"
            >
              <.icon name="hero-cog-6-tooth" class="size-6" />
            </.link>
            <.link
              navigate={~p"/dashboards/#{dashboard.id}/view"}
              class="flex h-full w-full items-center justify-between p-4"
              data-testid={dashboard.id <> "-dashboard-link"}
            >
              <div class="truncate">
                <div class="text flex">
                  <p class="truncate text-sm font-bold">
                    {dashboard.name}
                  </p>
                </div>
                <div class="mt-1 flex">
                  <div class="flex items-center text-xs text-gray-600">
                    <p></p>
                  </div>
                </div>
              </div>
              <div class="mt-4 flex-shrink-0 sm:mt-0 sm:ml-5">
                <div class="flex -space-x-1 space-x-4 overflow-hidden">
                  <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                    <.icon name="hero-chevron-right-mini" />
                  </div>
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
