defmodule DevhubWeb.Live.TerraDesk.Workspaces do
  @moduledoc false
  use DevhubWeb, :live_view

  use LiveSync,
    subscription_key: :organization_id,
    watch: [:workspaces]

  alias Devhub.Permissions
  alias Devhub.TerraDesk

  def mount(_params, _session, socket) do
    workspaces = TerraDesk.get_workspaces(organization_id: socket.assigns.organization.id)

    {:ok,
     assign(socket,
       page_title: "Devhub",
       workspaces: workspaces
     )}
  end

  def handle_params(params, _uri, socket) do
    filter = params["filter"] || "all"

    socket |> assign(filter: filter) |> noreply()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title="Workspaces">
        <:actions>
          <.link_button
            :if={Permissions.can?(:manage_terraform, @organization_user)}
            navigate={~p"/terradesk/workspaces/new"}
          >
            New workspace
          </.link_button>
          <div class="bg-alpha-4 divide-alpha-16 border-alpha-16 flex divide-x rounded border text-sm">
            <.link
              patch={~p"/terradesk?filter=pending"}
              class={"#{@filter == "pending" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
            >
              Pending
            </.link>
            <.link
              patch={~p"/terradesk"}
              class={"#{@filter == "all" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
            >
              All workspaces
            </.link>
          </div>
        </:actions>
      </.page_header>
      <div
        :if={Enum.empty?(@workspaces)}
        class="border-alpha-16 rounded-lg border-2 border-dashed p-12 text-center hover:border-alpha-24"
      >
        <.icon name="hero-folder-plus mx-auto h-12 w-12 text-gray-500" />
        <h3 class="mt-2 text-sm font-semibold text-gray-900">No workspaces</h3>
        <p class="mt-1 text-sm text-gray-500">
          TerraDesk allows managing your infrastructure as code platform using Terraform or Tofu. Create a workspace to get started.
        </p>
        <div class="mt-6">
          <.link_button
            :if={Permissions.can?(:manage_terraform, @organization_user)}
            navigate={~p"/terradesk/workspaces/new"}
          >
            New workspace
          </.link_button>
        </div>
      </div>
      <!-- Workspaces -->
      <div :if={not Enum.empty?(@workspaces)}>
        <ul role="list" class="divide-alpha-8 bg-surface-1 divide-y rounded-lg">
          <li
            :for={workspace <- @workspaces}
            :if={
              @filter == "all" or is_nil(workspace.latest_plan) or
                workspace.latest_plan.status != :applied
            }
            class="justify-content flex items-center hover:bg-alpha-4"
          >
            <.link
              :if={@permissions.super_admin}
              navigate={~p"/terradesk/workspaces/#{workspace.id}/settings"}
              class="ml-4 block text-sm text-gray-700"
            >
              <.icon name="hero-cog-6-tooth" class="size-5" />
            </.link>
            <.link
              navigate={~p"/terradesk/workspaces/#{workspace.id}"}
              class="relative flex w-full items-center justify-between p-4"
            >
              <div class="flex min-w-0 gap-x-4">
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-bold">
                    {workspace.name}
                  </p>
                  <p :if={workspace.repository} class="mt-1 flex text-xs text-gray-500">
                    {workspace.repository.owner}/{workspace.repository.name}
                  </p>
                </div>
              </div>
              <div class="flex shrink-0 items-center gap-x-4">
                <div
                  :if={not is_nil(workspace.latest_plan)}
                  class="hidden sm:flex sm:flex-col sm:items-end"
                >
                  <.terraform_status plan={workspace.latest_plan} />
                  <p class="mt-2 text-xs text-gray-500">
                    Last run
                    <format-date date={workspace.latest_plan.inserted_at}></format-date>
                  </p>
                </div>
                <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                  <.icon name="hero-chevron-right-mini" />
                </div>
              </div>
            </.link>
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
