defmodule DevhubWeb.Live.TerraDesk.Workspace do
  @moduledoc false
  use DevhubWeb, :live_view

  use LiveSync,
    subscription_key: :organization_id,
    watch: [
      plans: [schema: Devhub.TerraDesk.Schemas.Plan]
    ]

  alias Devhub.Permissions
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Utils.AnsiToHTML
  alias Phoenix.PubSub

  def mount(%{"id" => id}, _session, socket) do
    {:ok, workspace} = TerraDesk.get_workspace(id: id, organization_id: socket.assigns.organization.id)
    plans = TerraDesk.get_recent_plans(workspace)

    if connected?(socket) do
      PubSub.unsubscribe(Devhub.PubSub, workspace.id)
      PubSub.subscribe(Devhub.PubSub, workspace.id)
    end

    {:ok,
     assign(socket,
       page_title: "#{workspace.name} | Devhub",
       workspace: workspace,
       plans: plans,
       log: "",
       form: to_form(%{"lock_id" => ""}),
       breadcrumbs: [%{title: workspace.name}]
     )}
  end

  def sync(:plans, updated, socket) do
    updates =
      updated
      |> Enum.filter(&(&1.workspace_id == socket.assigns.workspace.id))
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(10)
      |> Devhub.Repo.preload([:user])

    assign(socket, plans: updates)
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header
        title={@workspace.name}
        subtitle={
          @workspace.repository && "#{@workspace.repository.owner}/#{@workspace.repository.name}"
        }
      >
        <:actions>
          <.dropdown
            :if={Permissions.can?(:approve, @workspace, @organization_user)}
            id="workspace-actions"
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
                class="bg-alpha-4 ring-alpha-24 flex w-48 items-center justify-between rounded px-3 py-2 text-sm ring-1 transition-all ease-in-out"
              >
                <div><span class="text-alpha-40 mr-1">Actions:</span> Select...</div>
                <.icon name="hero-chevron-down" class="h-4 w-4" />
              </div>
            </:trigger>
            <div class="divide-alpha-8 bg-surface-2 mt-2 w-48 divide-y rounded px-3 py-1 py-4 text-xs ring-1 ring-gray-100 ring-opacity-5">
              <div class="flex flex-col items-start gap-y-3 px-1 pb-3">
                <.link
                  :if={not is_nil(@workspace.agent_id) or not Devhub.cloud_hosted?()}
                  navigate={~p"/terradesk/workspaces/#{@workspace.id}/plan"}
                  class="flex items-center gap-x-2"
                >
                  <.icon name="devhub-aim" class="h-4 w-4 text-gray-600 hover:text-gray-500" />
                  Targeted plan
                </.link>
                <button phx-click={show_modal("run-plan-modal")} class="flex items-center gap-x-2">
                  <.icon name="hero-wrench" class="h-4 w-4" /> Plan
                </button>
                <button phx-click={show_modal("move-state-modal")} class="flex items-center gap-x-2">
                  <.icon name="hero-arrows-right-left" class="h-4 w-4" /> Move state
                </button>
              </div>
              <div :if={Permissions.can?(:manage_terraform, @organization_user)} class="px-1 py-3">
                <.link
                  navigate={~p"/terradesk/workspaces/#{@workspace.id}/settings"}
                  class="flex items-center gap-x-2"
                >
                  <.icon name="hero-cog-6-tooth" class="h-4 w-4 text-gray-600 hover:text-gray-500" />
                  Workspace settings
                </.link>
              </div>
              <div class="px-1 pt-3">
                <button
                  phx-click={show_modal("unlock-modal")}
                  class="flex items-center gap-x-2 text-red-500"
                >
                  <.icon name="hero-lock-open" class="h-4 w-4" /> Unlock
                </button>
              </div>
            </div>
          </.dropdown>
        </:actions>
      </.page_header>

      <.modal id="run-plan-modal">
        <.form
          :let={f}
          for={%{"branch" => @workspace.repository.default_branch}}
          phx-submit="run_plan"
        >
          <div>
            <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-blue-200">
              <.icon name="hero-wrench" class="size-6 text-blue-800" />
            </div>
            <div class="mt-2 text-center">
              <h3 class="text-base font-semibold text-gray-900">
                Run plan
              </h3>
            </div>
          </div>
          <div class="my-6">
            <.input field={f[:branch]} label="Branch" />
          </div>
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#run-plan-modal")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit">Run Plan</.button>
          </div>
        </.form>
      </.modal>

      <.modal id="unlock-modal" title="Unlock State" size="medium" on_cancel={JS.push("clear_log")}>
        <.form :if={@log == ""} for={@form} phx-submit="unlock_state">
          <div>
            <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-200">
              <.icon name="hero-lock-open" class="size-6 text-red-800" />
            </div>
            <div class="mt-2 text-center">
              <h3 class="text-base font-semibold text-gray-900">
                Force unlock state
              </h3>
              <div class="mt-1">
                <p class="text-sm text-gray-500">
                  You should only use this action if a plan failed. Be careful not to force unlock state when the state is in use.
                </p>
              </div>
            </div>
          </div>
          <div class="my-6">
            <.input field={@form[:lock_id]} label="lock id" />
          </div>
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#unlock-modal")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit" variant="destructive">Unlock</.button>
          </div>
        </.form>

        <div
          :if={byte_size(@log) > 0}
          class="bg-alpha-4 max-h-[80vh] mt-4 block overflow-auto rounded p-2"
          id="unlock-output"
          phx-hook="ScrollToEnd"
        >
          {raw(AnsiToHTML.generate_html(@log))}
        </div>
      </.modal>

      <.modal id="move-state-modal" title="Move State" size="medium" on_cancel={JS.push("clear_log")}>
        <.form :if={@log == ""} for={@form} phx-submit="move_state">
          <div>
            <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-blue-200">
              <.icon name="hero-arrows-right-left" class="size-6 text-blue-800" />
            </div>
            <div class="mt-2 text-center">
              <h3 class="text-base font-semibold text-gray-900">
                Move state
              </h3>
              <div class="mt-1">
                <p class="text-sm text-gray-500">
                  Provide the source and destination address for the resource you want to move.
                </p>
              </div>
            </div>
          </div>
          <div class="my-6 flex flex-col gap-4">
            <.input field={@form[:from]} label="From" />
            <.input field={@form[:to]} label="To" />
          </div>
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#move-state-modal")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit">Move</.button>
          </div>
        </.form>

        <div
          :if={byte_size(@log) > 0}
          class="bg-alpha-4 max-h-[80vh] mt-4 block overflow-auto rounded p-2"
          id="unlock-output"
          phx-hook="ScrollToEnd"
        >
          {raw(AnsiToHTML.generate_html(@log))}
        </div>
      </.modal>

      <div class="bg-surface-1 rounded-lg">
        <h1 class="border-alpha-16 border-b p-4 text-xl font-bold">Recent Plans</h1>

        <ul role="list" class="divide-alpha-8 divide-y">
          <li :for={plan <- @plans} class="relative ">
            <.link navigate={~p"/terradesk/plans/#{plan.id}"} class="flex justify-between gap-x-4 p-4">
              <div class="flex min-w-0 items-center gap-x-4">
                <img
                  :if={not is_nil(plan.user) and not is_nil(plan.user.picture)}
                  class="size-10 flex-none rounded-full"
                  src={plan.user.picture}
                />
                <.icon :if={is_nil(plan.user)} name="devhub-github" class="size-10" />
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold">
                    {plan.github_branch}
                  </p>
                  <p class="mt-1 flex text-xs text-gray-500">
                    <span :if={not is_nil(plan.user)} class="mr-1">
                      Triggered by: <span class="font-bold">{plan.user.name}</span>
                    </span>
                    <span :if={is_nil(plan.user)} class="mr-1">
                      Triggered by: <span class="font-bold">GitHub</span>
                    </span>
                    <span :if={plan.commit_sha}>| {plan.commit_sha}</span>
                  </p>
                </div>
              </div>
              <div class="flex shrink-0 items-center gap-x-4">
                <div class="hidden sm:flex sm:flex-col sm:items-end">
                  <.terraform_status plan={plan} />
                  <p class="mt-2 text-xs text-gray-500">
                    <format-date date={plan.inserted_at}></format-date>
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

  def handle_info({:shell_output, log}, socket) do
    {:noreply,
     socket
     |> assign(log: socket.assigns.log <> log)
     |> push_event("scroll_to_end", %{})}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  def handle_event("clear_log", _params, socket) do
    {:noreply, assign(socket, log: "")}
  end

  def handle_event("run_plan", %{"branch" => branch}, socket) do
    workspace = socket.assigns.workspace

    cond do
      Devhub.cloud_hosted?() and is_nil(workspace.agent_id) ->
        socket |> put_flash(:error, "Agent is required for cloud hosted installs") |> noreply()

      Permissions.can?(:approve, workspace, socket.assigns.organization_user) ->
        {:ok, plan} = TerraDesk.create_plan(workspace, branch, user: socket.assigns.user, run: true)

        {:noreply, push_navigate(socket, to: ~p"/terradesk/plans/#{plan.id}")}

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("unlock_state", _params, socket) do
    workspace = socket.assigns.workspace

    if Permissions.can?(:approve, workspace, socket.assigns.organization_user) do
      lock_id = socket.assigns.form.params["lock_id"]

      Task.Supervisor.async_nolink(Devhub.TaskSupervisor, fn ->
        TerraDesk.unlock_terraform_state(socket.assigns.workspace, lock_id)
      end)

      {:noreply, assign(socket, log: "Starting job...\n")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("move_state", %{"from" => from, "to" => to}, socket) do
    workspace = socket.assigns.workspace

    if Permissions.can?(:approve, workspace, socket.assigns.organization_user) do
      Task.Supervisor.async_nolink(Devhub.TaskSupervisor, fn ->
        TerraDesk.move_terraform_state(socket.assigns.workspace, from, to)
      end)

      {:noreply, assign(socket, log: "Starting job...\n")}
    else
      {:noreply, socket}
    end
  end
end
