defmodule DevhubWeb.Live.TerraDesk.Plan do
  @moduledoc false
  use DevhubWeb, :live_view

  use LiveSync,
    subscription_key: :organization_id,
    watch: [:plan]

  alias Devhub.Permissions
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Jobs.RunPlan
  alias Devhub.TerraDesk.Utils.AnsiToHTML
  alias Devhub.Users
  alias Phoenix.PubSub

  def mount(%{"plan_id" => id}, _session, socket) do
    {:ok, plan} = TerraDesk.get_plan(id: id, organization_id: socket.assigns.organization.id)

    if connected?(socket) do
      PubSub.subscribe(Devhub.PubSub, plan.id)
    end

    {:ok,
     assign(socket,
       page_title: "Devhub",
       plan: plan,
       log: plan.log || "",
       selected_resources: %{},
       breadcrumbs: [
         %{title: plan.workspace.name, path: ~p"/terradesk/workspaces/#{plan.workspace.id}"},
         %{title: "Plan"}
       ]
     )}
  end

  def sync(:plan, updated, socket) do
    log = updated.log || socket.assigns.log
    plan = %{updated | log: log}
    assign(socket, plan: plan, log: log)
  end

  def render(assigns) do
    assigns =
      assign(assigns,
        approvals: length(assigns.plan.approvals || []),
        changes: TerraDesk.plan_changes(assigns.plan)
      )

    ~H"""
    <div id="plan" phx-hook="ScrollToEnd">
      <.page_header
        title={@plan.workspace.name}
        subtitle={
          @plan.workspace.repository &&
            "#{@plan.workspace.repository.owner}/#{@plan.workspace.repository.name}"
        }
      >
        <:actions>
          <span class="text-xs"><format-date date={@plan.updated_at} format="relative" /></span>
          <.terraform_status plan={@plan} />
          <.button
            :if={
              @plan.status == :queued and
                Permissions.can?(:approve, @plan.workspace, @organization_user)
            }
            phx-click="run_plan"
          >
            Run Plan
          </.button>
          <.button
            :if={
              @plan.status in [:failed, :canceled] and
                Permissions.can?(:approve, @plan.workspace, @organization_user)
            }
            phx-click="retry_plan"
          >
            Retry
          </.button>
          <div class="flex items-center gap-x-4">
            <div :if={@plan.workspace.required_approvals > 0} class="flex flex-col items-end">
              <p class="text-xs">
                {@approvals} / {@plan.workspace.required_approvals}
              </p>
              <p class="text-alpha-64 text-xs">
                approvals
              </p>
            </div>
            <.button
              :if={
                @plan.status == :planned and @approvals < @plan.workspace.required_approvals and
                  Permissions.can?(:approve, @plan.workspace, @organization_user)
              }
              id="approve-plan"
              phx-click="approve_plan"
              phx-hook="Passkey"
              disabled={already_approved(@plan, @organization_user.id)}
            >
              Approve
            </.button>
            <.button
              :if={
                @plan.status == :running and
                  Permissions.can?(:approve, @plan.workspace, @organization_user)
              }
              id="cancel-plan"
              phx-click="cancel_plan"
              variant="destructive"
              data-confirm="Are you sure you want to cancel this plan? It could leave your state locked or have other unintended consequences."
            >
              Cancel
            </.button>
          </div>
          <.button
            :if={
              @plan.status == :planned and @approvals >= @plan.workspace.required_approvals and
                Permissions.can?(:approve, @plan.workspace, @organization_user)
            }
            phx-click="run_apply"
          >
            Apply
          </.button>
          <.button
            :if={not Enum.empty?(@selected_resources)}
            phx-click="new_targeted_plan"
            variant="secondary"
          >
            New targeted Plan
          </.button>
        </:actions>
      </.page_header>

      <.form :let={f} for={@selected_resources} phx-change="select_resources">
        <ul
          :if={not Enum.empty?(@changes)}
          role="list"
          class="divide-alpha-8 bg-surface-1 mb-4 divide-y rounded-lg"
        >
          <li
            :for={
              {%{name: name, summary: summary, details: details}, index} <- Enum.with_index(@changes)
            }
            class="flex items-start p-4"
          >
            <div class="pt-3">
              <.input type="checkbox" field={f[URI.encode_www_form(name)]} />
            </div>
            <div class="align flex w-full flex-col">
              <div
                phx-click={
                  JS.toggle(
                    to: "#changes-#{index}",
                    in: {"transition-all transform ease-out", "opacity-0", "opacity-100"},
                    out: {"transition-all transform ease-in", "opacity-100", "opacity-0"}
                  )
                  |> JS.toggle_class("rotate-90", to: "#icon-#{index}")
                }
                class="flex cursor-pointer items-center justify-between py-2"
              >
                {raw(summary)}
                <span id={"icon-#{index}"} class="ml-auto">
                  <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                    <.icon name="hero-chevron-right-mini" />
                  </div>
                </span>
              </div>
              <div
                id={"changes-#{index}"}
                class="bg-alpha-4 min-h-12 mt-4 hidden overflow-x-auto rounded p-4"
              >
                {raw(details)}
              </div>
            </div>
          </li>
        </ul>
      </.form>

      <div class="bg-surface-1 min-h-12 block overflow-x-auto rounded-lg p-4" id="plan-output">
        <span :if={@log == "" and @plan.status == :running}>Waiting for logs...</span>
        {raw(AnsiToHTML.generate_html(@log))}
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

  def handle_event("approve_plan", params, socket) do
    organization_user = socket.assigns.organization_user
    plan = socket.assigns.plan

    cond do
      not Permissions.can?(:approve, plan.workspace, organization_user) ->
        {:noreply, socket}

      not socket.assigns.mfa_enabled? ->
        {:ok, plan} = TerraDesk.approve_plan(plan, organization_user)
        socket |> assign(plan: plan) |> noreply()

      is_nil(params["authenticatorData"]) ->
        socket |> start_passkey_authentication(socket.assigns.user, "approve_plan") |> noreply()

      true ->
        case Users.authenticate_passkey(params, socket.assigns.challenge, socket.assigns.allow_credentials) do
          :ok ->
            {:ok, plan} = TerraDesk.approve_plan(plan, organization_user)
            socket |> assign(plan: plan) |> noreply()

          {:error, _error} ->
            socket |> put_flash(:error, "Passkey verification failed.") |> noreply()
        end
    end
  end

  def handle_event("run_plan", _params, socket) do
    organization_user = socket.assigns.organization_user
    plan = socket.assigns.plan

    if Permissions.can?(:approve, plan.workspace, organization_user) do
      %{id: plan.id}
      |> RunPlan.new(queue: :terradesk)
      |> Oban.insert()

      {:noreply, assign(socket, plan: %{plan | status: :running})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("retry_plan", _params, socket) do
    TerraDesk.retry_plan(socket.assigns.plan)
    {:noreply, socket}
  end

  def handle_event("run_apply", _params, socket) do
    organization_user = socket.assigns.organization_user
    plan = socket.assigns.plan

    if Permissions.can?(:approve, plan.workspace, organization_user) do
      Task.Supervisor.async_nolink(Devhub.TaskSupervisor, fn ->
        TerraDesk.run_apply(plan)
      end)
    end

    {:noreply, socket}
  end

  def handle_event("cancel_plan", _params, socket) do
    organization_user = socket.assigns.organization_user
    plan = socket.assigns.plan

    if Permissions.can?(:approve, plan.workspace, organization_user) do
      TerraDesk.cancel_plan(plan)
    end

    {:noreply, socket}
  end

  def handle_event("select_resources", params, socket) do
    params = params |> Enum.filter(fn {_key, value} -> value == "true" end) |> Map.new()
    socket |> assign(selected_resources: params) |> noreply()
  end

  def handle_event("new_targeted_plan", _params, socket) do
    selected_resources = Enum.map(socket.assigns.selected_resources, fn {resource, _true} -> URI.decode(resource) end)

    workspace = socket.assigns.plan.workspace

    {:ok, plan} =
      TerraDesk.create_plan(
        workspace,
        socket.assigns.plan.github_branch,
        user: socket.assigns.user,
        targeted_resources: selected_resources,
        run: true
      )

    socket |> push_navigate(to: ~p"/terradesk/plans/#{plan.id}") |> noreply()
  end

  defp already_approved(plan, organization_user_id) do
    Enum.any?(plan.approvals || [], &(&1.organization_user_id == organization_user_id))
  end
end
