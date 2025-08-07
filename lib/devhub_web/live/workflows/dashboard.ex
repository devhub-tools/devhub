defmodule DevhubWeb.Live.Workflows.Dashboard do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Workflows

  def mount(_params, _session, socket) do
    %{organization: organization, organization_user: organization_user} = socket.assigns
    workflows = Workflows.list_workflows(organization.id)
    waiting_workflows = Workflows.my_waiting_workflows(organization_user)

    socket
    |> assign(
      page_title: "Devhub",
      workflows: workflows,
      waiting_workflows: waiting_workflows
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header title="Workflows">
        <:actions>
          <.link_button
            href="https://docs.querydesk.com/guides/workflows"
            target="_blank"
            variant="text"
          >
            Docs
          </.link_button>

          <.button
            :if={@permissions.super_admin}
            data-testid="add-workflow-button"
            phx-click={show_modal("add-workflow")}
          >
            Add workflow
          </.button>
        </:actions>
      </.page_header>

      <div
        :if={Enum.empty?(@workflows) and @permissions.super_admin}
        class="bg-surface-1 rounded-lg p-8"
      >
        <div>
          <h2 class="text-base font-semibold text-gray-900">Create your first workflow</h2>
          <p class="mt-1 text-sm text-gray-500">
            Workflows allow you to automate tasks and processes across your organization, reducing the need for developers to spend time building custom dashboards or performing manual tasks.
          </p>
          <ul role="list" class="divide-alpha-8 border-alpha-8 mt-6 divide-y border-t border-b">
            <li
              phx-click="add_workflow"
              phx-value-name="My first query workflow"
              phx-value-step_type="query"
              role="button"
            >
              <div class="group relative flex items-start space-x-3 py-4">
                <div class="shrink-0">
                  <span class="size-10 inline-flex items-center justify-center rounded-lg bg-blue-500">
                    <.icon name="hero-circle-stack" class="size-6 text-gray-900" />
                  </span>
                </div>
                <div class="min-w-0 flex-1">
                  <div class="text-sm font-medium text-gray-900">
                    <a href="#">
                      <span class="absolute inset-0" aria-hidden="true"></span> Run a query
                    </a>
                  </div>
                  <p class="text-sm text-gray-500">
                    Execute database queries safely with a built-in review process and compliance controls.
                  </p>
                </div>
                <div class="shrink-0 self-center">
                  <.icon
                    name="hero-chevron-right-mini"
                    class="size-5 text-gray-400 group-hover:text-gray-500"
                  />
                </div>
              </div>
            </li>
            <li
              phx-click="add_workflow"
              phx-value-name="My first slack workflow"
              phx-value-step_type="slack"
              role="button"
            >
              <div class="group relative flex items-start space-x-3 py-4">
                <div class="shrink-0">
                  <span class="size-10 inline-flex items-center justify-center rounded-lg bg-yellow-500">
                    <.icon name="hero-chat-bubble-left-ellipsis" class="size-6 text-gray-900" />
                  </span>
                </div>
                <div class="min-w-0 flex-1">
                  <div class="text-sm font-medium text-gray-900">
                    <a href="#">
                      <span class="absolute inset-0" aria-hidden="true"></span> Send a slack message
                    </a>
                  </div>
                  <p class="text-sm text-gray-500">
                    Automate notifications to your team channels when important events occur or need to be reviewed.
                  </p>
                </div>
                <div class="shrink-0 self-center">
                  <.icon
                    name="hero-chevron-right-mini"
                    class="size-5 text-gray-400 group-hover:text-gray-500"
                  />
                </div>
              </div>
            </li>
            <li
              phx-click="add_workflow"
              phx-value-name="My first api workflow"
              phx-value-step_type="api"
              role="button"
            >
              <div class="group relative flex items-start space-x-3 py-4">
                <div class="shrink-0">
                  <span class="size-10 inline-flex items-center justify-center rounded-lg bg-purple-500">
                    <.icon name="hero-cloud" class="size-6 text-gray-900" />
                  </span>
                </div>
                <div class="min-w-0 flex-1">
                  <div class="text-sm font-medium text-gray-900">
                    <a href="#">
                      <span class="absolute inset-0" aria-hidden="true"></span> Trigger an API request
                    </a>
                  </div>
                  <p class="text-sm text-gray-500">
                    Send custom API requests to external services to automate tasks and integrations.
                  </p>
                </div>
                <div class="shrink-0 self-center">
                  <.icon
                    name="hero-chevron-right-mini"
                    class="size-5 text-gray-400 group-hover:text-gray-500"
                  />
                </div>
              </div>
            </li>
            <li
              phx-click="add_workflow"
              phx-value-name="My first approval workflow"
              phx-value-step_type="approval"
              role="button"
            >
              <div class="group relative flex items-start space-x-3 py-4">
                <div class="shrink-0">
                  <span class="size-10 inline-flex items-center justify-center rounded-lg bg-green-500">
                    <.icon name="hero-check-circle" class="size-6 text-gray-900" />
                  </span>
                </div>
                <div class="min-w-0 flex-1">
                  <div class="text-sm font-medium text-gray-900">
                    <a href="#">
                      <span class="absolute inset-0" aria-hidden="true"></span> Require an approval
                    </a>
                  </div>
                  <p class="text-sm text-gray-500">
                    Add human verification to critical operations with built-in approval workflows.
                  </p>
                </div>
                <div class="shrink-0 self-center">
                  <.icon
                    name="hero-chevron-right-mini"
                    class="size-5 text-gray-400 group-hover:text-gray-500"
                  />
                </div>
              </div>
            </li>
          </ul>
          <div class="mt-6 flex">
            <.button
              variant="text"
              size="sm"
              phx-click="add_workflow"
              phx-value-name="My first workflow"
            >
              Or start with an empty workflow <span aria-hidden="true"> &rarr;</span>
            </.button>
          </div>
        </div>
      </div>

      <.workflow_list
        workflows={@workflows}
        permissions={@permissions}
        waiting_workflows={@waiting_workflows}
      />

      <.modal id="add-workflow">
        <.form
          for={%{}}
          phx-submit={JS.push("add_workflow") |> hide_modal("add-workflow")}
          data-testid="add-workflow-form"
        >
          <.input label="Workflow name" name="name" value="" />
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#add-workflow")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit" variant="primary">Create</.button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  def handle_event("add_workflow", %{"name" => name, "step_type" => step_type}, socket) do
    {:ok, workflow} =
      Workflows.create_workflow(%{
        name: name,
        organization_id: socket.assigns.organization.id,
        steps: [%{action: %{__type__: step_type}}]
      })

    socket |> push_navigate(to: ~p"/workflows/#{workflow.id}/edit") |> noreply()
  end

  def handle_event("add_workflow", %{"name" => name}, socket) do
    case Workflows.create_workflow(%{name: name, organization_id: socket.assigns.organization.id}) do
      {:ok, workflow} ->
        socket |> push_navigate(to: ~p"/workflows/#{workflow.id}/edit") |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to create workflow") |> noreply()
    end
  end

  defp workflow_list(assigns) do
    ~H"""
    <ul role="list" class="divide-alpha-16 bg-surface-1 divide-y rounded-lg">
      <li :for={workflow <- @workflows} class="hover:bg-alpha-4">
        <div class="flex items-center">
          <div class="flex min-w-0 flex-1 items-center justify-between">
            <.link
              :if={@permissions.super_admin}
              navigate={~p"/workflows/#{workflow.id}/edit"}
              class="ml-4 block text-sm text-gray-700"
            >
              <.icon name="hero-cog-6-tooth" class="size-6" />
            </.link>
            <.link
              navigate={~p"/workflows/#{workflow.id}"}
              class="flex h-full w-full items-center justify-between p-4"
            >
              <div class="truncate">
                <div class="text flex">
                  <p class="truncate text-sm font-bold">
                    {workflow.name}
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
                  <.badge
                    :if={@waiting_workflows[workflow.id]}
                    label={pluralize_unit(@waiting_workflows[workflow.id], "waiting workflow")}
                    color="blue"
                  />
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
