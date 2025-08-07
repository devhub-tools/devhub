defmodule DevhubWeb.Live.Workflows.EditWorkflow do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations.Linear
  alias Devhub.QueryDesk
  alias Devhub.Utils
  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Step
  alias Devhub.Workflows.Schemas.Workflow

  def mount(%{"id" => id}, _session, socket) do
    %{organization: organization} = socket.assigns
    {:ok, workflow} = Workflows.get_workflow(id: id, organization_id: organization.id)
    workflow = %{workflow | steps: Enum.map(workflow.steps, &Utils.sort_permissions/1)}

    linear_labels = Linear.list_labels(organization.id)

    credentials = QueryDesk.list_credential_options(socket.assigns.organization_user)

    socket
    |> assign(
      page_title: "Devhub",
      workflow: workflow,
      changeset: Workflow.changeset(workflow, %{}),
      credentials: credentials,
      show_saved: false,
      linear_labels: linear_labels,
      breadcrumbs: [
        %{title: "Workflows", path: ~p"/workflows"},
        %{title: workflow.name, path: ~p"/workflows/#{workflow.id}"},
        %{title: "Edit"}
      ]
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header title={@workflow.name}>
        <:actions>
          <p :if={@show_saved} class="flex items-center gap-x-1 text-green-500 transition-all">
            <.icon name="hero-check-circle" class="size-6" />Saved
          </p>
          <.link_button
            href="https://docs.querydesk.com/guides/workflows"
            target="_blank"
            variant="text"
          >
            Docs
          </.link_button>
          <.link_button navigate={~p"/workflows/#{@workflow.id}"}>
            Done
          </.link_button>
        </:actions>
      </.page_header>

      <.form :let={f} for={@changeset} phx-change="update">
        <div class="bg-surface-1 relative flex flex-col gap-y-4 rounded-lg p-4">
          <.input field={f[:name]} label="Workflow name" phx-debounce />
          <.input
            field={f[:cron_schedule]}
            label="Schedule"
            tooltip="A cron expression evaluated using UTC time to trigger the workflow."
            phx-debounce
          />
          <.select_with_search
            :if={not Enum.empty?(@linear_labels)}
            id={f.id <> "-label"}
            form={f}
            label="Linear label trigger"
            selected={
              Enum.find_value(@linear_labels, &(&1.id == f.data.trigger_linear_label_id && &1.name))
            }
            field={:trigger_linear_label_id}
            search_field={:trigger_linear_label_search}
            search_fun={
              fn search ->
                Enum.filter(@linear_labels, &String.contains?(String.downcase(&1.name), search))
              end
            }
          >
            <:item :let={label}>
              <div
                data-testid={label.id <> "-option"}
                class="flex items-center truncate text-sm font-semibold"
              >
                <div class="size-2 mr-4 rounded-full" style={"background-color: #{label.color}"}>
                </div>
                <div class="flex flex-col gap-y-1">
                  <p>{label.name}</p>
                  <p class="text-alpha-64 text-xs">
                    {(label.team && "Team label: #{label.team.name}") || "Workspace label"}
                  </p>
                </div>
              </div>
            </:item>
          </.select_with_search>
          <p class="mb-4 text-xl font-medium">Inputs</p>
          <.inputs_for :let={input} field={f[:inputs]}>
            <div class="mb-4 flex items-center gap-x-2">
              <input type="hidden" name="workflow[input_sort][]" value={input.index} />
              <div class="flex-1">
                <.input
                  field={input[:type]}
                  label="type"
                  type="select"
                  options={Ecto.Enum.values(Devhub.Workflows.Schemas.Workflow.Input, :type)}
                />
              </div>
              <div class="flex-1">
                <.input field={input[:key]} label="Field" phx-debounce />
              </div>
              <div class="flex-1">
                <.input field={input[:description]} label="Description" phx-debounce />
              </div>
              <label class="flex items-center align-text-bottom">
                <input
                  type="checkbox"
                  name="workflow[input_drop][]"
                  value={input.index}
                  class="hidden"
                />
                <div class="bg-alpha-4 size-6 mt-6 flex items-center justify-center rounded">
                  <.icon name="hero-x-mark-mini" class="h-5 w-5 align-bottom text-gray-900" />
                </div>
              </label>
            </div>
          </.inputs_for>

          <label class="mx-auto flex h-8 w-fit items-center whitespace-nowrap rounded p-2 text-sm font-bold text-blue-800 ring-1 ring-inset ring-blue-300 transition-colors disabled:pointer-events-none disabled:opacity-50">
            <input type="checkbox" name="workflow[input_sort][]" class="hidden" />
            <div class="flex items-center gap-x-2">
              <.icon name="hero-plus-mini" class="size-5" /> Add input
            </div>
          </label>
        </div>

        <div class="my-2 flex w-full items-center justify-center">
          <.icon name="hero-arrow-down-mini" class="size-10 text-alpha-32" />
        </div>

        <div id="steps" phx-hook="Sortable">
          <.inputs_for :let={step} field={f[:steps]}>
            <div class="sortable-item">
              <div class="flex gap-x-2">
                <input type="hidden" name="workflow[step_sort][]" value={step.index} />
                <.icon
                  name="devhub-drag-handle"
                  class="sortable-handle size-6 mt-1 cursor-grab text-gray-600"
                />
                <div class="flex-1">
                  <.step step={step} credentials={@credentials} changeset={@changeset} />
                </div>
              </div>

              <div class="my-2 flex w-full items-center justify-center">
                <.icon name="hero-arrow-down-mini" class="size-10 text-alpha-32" />
              </div>
            </div>
          </.inputs_for>

          <div
            phx-click="add_step"
            class="mx-auto flex h-8 w-fit cursor-pointer items-center whitespace-nowrap rounded p-2 text-sm font-bold text-blue-800 ring-1 ring-inset ring-blue-300 transition-colors disabled:pointer-events-none disabled:opacity-50"
          >
            <div class="flex items-center gap-x-2">
              <.icon name="hero-plus-mini" class="size-5" /> Add step
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event(
        "update",
        %{"_target" => ["workflow", "steps", _index, "action", "credential_search"], "workflow" => params},
        socket
      ) do
    changeset = Workflow.changeset(socket.assigns.workflow, params)
    socket |> assign(changeset: changeset) |> noreply()
  end

  def handle_event("update", %{"workflow" => params, "_target" => target}, socket) do
    case Workflows.update_workflow(socket.assigns.workflow, params) do
      {:ok, workflow} ->
        workflow =
          if target == ["workflow", "trigger_linear_label_id"] do
            %{workflow | trigger_linear_label_search: nil}
          else
            workflow
          end

        changeset = Workflow.changeset(workflow, %{})

        with %{timer_ref: timer_ref} <- socket.assigns do
          Process.cancel_timer(timer_ref, async: true, info: false)
        end

        timer_ref = Process.send_after(self(), :saved, 500)

        socket
        |> assign(workflow: workflow, changeset: changeset, timer_ref: timer_ref)
        |> noreply()

      {:error, changeset} ->
        socket |> assign(changeset: changeset) |> noreply()
    end
  end

  def handle_event("add_step", _params, socket) do
    existing_steps = Ecto.Changeset.get_field(socket.assigns.changeset, :steps)
    new_steps = [%Step{action: %Step.QueryAction{}, permissions: []}]

    steps = Enum.concat(existing_steps, new_steps)

    changeset = Ecto.Changeset.put_change(socket.assigns.changeset, :steps, steps)

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  def handle_event("select_step_id", %{"step_id" => step_id}, socket) do
    socket |> assign(step_id: step_id) |> noreply()
  end

  def handle_info(:saved, socket) do
    timer_ref = Process.send_after(self(), :remove_saved, 3_000)

    socket |> assign(show_saved: true, timer_ref: timer_ref) |> noreply()
  end

  def handle_info(:remove_saved, socket) do
    socket |> assign(show_saved: false) |> noreply()
  end

  defp step(assigns) do
    ~H"""
    <div class="bg-surface-1 relative rounded-lg p-4 text-center">
      <label class="absolute top-2 right-2 cursor-pointer">
        <input type="checkbox" name="workflow[step_drop][]" value={@step.index} class="hidden" />
        <span class="text-red-400">Remove step</span>
      </label>

      <.polymorphic_embed_inputs_for :let={action_form} field={@step[:action]} skip_hidden={true}>
        <div class="mb-4 flex flex-col gap-y-4">
          <.input
            field={action_form[:__type__]}
            type="select"
            options={
              PolymorphicEmbed.types(Devhub.Workflows.Schemas.Step, :action)
              |> Enum.map(&{&1 |> to_string |> String.replace("_", " "), &1})
            }
            value={get_polymorphic_type(@step, :action)}
            label="Action type"
          />
          <.input field={@step[:name]} label="Step name" phx-debounce />
          <.input
            field={@step[:condition]}
            label="Run if"
            tooltip="Expression to evaluate if this step should run, if evaluated as true step will run, otherwise it will be skipped. If no condition is set the step will always run. You can use the input, output from previous steps, and basic operators like ==, !=, >, <, >=, <=, &&, ||, not."
            phx-debounce
          />
        </div>
        <.action
          step_form={@step}
          action_form={action_form}
          source_module={source_module(action_form)}
          credentials={@credentials}
          changeset={@changeset}
        />
      </.polymorphic_embed_inputs_for>
    </div>
    """
  end

  defp action(%{source_module: Step.ApiAction} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-4 text-left">
      <.input field={@action_form[:endpoint]} label="Endpoint" phx-debounce />
      <.input
        field={@action_form[:method]}
        type="select"
        options={Ecto.Enum.values(Devhub.Workflows.Schemas.Step.ApiAction, :method)}
        label="Method"
        phx-debounce
      />
      <div class="col-span-5 flex flex-col gap-y-4">
        <div>
          <div class="flex items-center gap-x-1">
            <p class="text-alpha-64 text-xs uppercase">Headers</p>
            <div class="tooltip-right tooltip">
              <span class="bg-alpha-16 text-alpha-64 size-4 relative flex items-center justify-center rounded-full text-xs">
                ?
              </span>
              <span class="tooltiptext w-64 p-2">All header values are stored encrypted</span>
            </div>
          </div>

          <.inputs_for :let={header} field={@action_form[:headers]}>
            <input type="hidden" name={"#{@action_form.name}[header_sort][]"} value={header.index} />
            <div class="mb-1 flex items-center gap-x-4">
              <div class="flex-1">
                <.input field={header[:key]} placeholder="key" autocomplete="off" phx-debounce />
              </div>

              <div class="flex-1">
                <.input field={header[:value]} placeholder="value" autocomplete="off" phx-debounce />
              </div>

              <label class="col-span-1 flex items-center align-text-bottom">
                <input
                  type="checkbox"
                  name={"#{@action_form.name}[header_drop][]"}
                  value={header.index}
                  class="hidden"
                />
                <div class="bg-alpha-4 size-6 mt-2 flex items-center justify-center rounded-md">
                  <.icon name="hero-x-mark-mini" class="h-5 w-5 align-bottom text-gray-900" />
                </div>
              </label>
            </div>
          </.inputs_for>
        </div>

        <label class="flex h-8 w-fit cursor-pointer items-center whitespace-nowrap rounded-md p-2 text-sm font-bold text-blue-800 ring-1 ring-inset ring-blue-300 transition-colors disabled:pointer-events-none disabled:opacity-50">
          <input type="checkbox" name={"#{@action_form.name}[header_sort][]"} class="hidden" />
          <div class="flex items-center gap-x-2">
            <.icon name="hero-plus-mini" class="h-5 w-5" /> Add header
          </div>
        </label>
      </div>
      <.input field={@action_form[:body]} type="textarea" label="Body" phx-debounce />
      <.input field={@action_form[:expected_status_code]} label="Expected status code" phx-debounce />
      <.input
        field={@action_form[:include_devhub_jwt]}
        tooltip="JWT will be available in the x-devhub-jwt header."
        type="checkbox"
        label="Include Devhub JWT"
      />
    </div>
    """
  end

  defp action(%{source_module: Step.ApprovalAction} = assigns) do
    ~H"""
    <.input field={@action_form[:reviews_required]} label="Reviews required" phx-debounce />
    <div class="mt-4 flex flex-col gap-y-4">
      <div>
        <p class="text-alpha-64 mb-2 block text-left text-xs uppercase">Approvers</p>
        <div class="flex flex-col gap-y-2">
          <.inputs_for :let={permission} field={@step_form[:permissions]}>
            <input
              type="hidden"
              name={"#{@step_form.name}[permission_sort][]"}
              value={permission.index}
            />
            <div class="ring-alpha-16 flex items-center gap-x-4 rounded p-4 ring-1">
              <div class="flex-1">
                <.user_block
                  :if={permission.data.organization_user}
                  user={permission.data.organization_user.user}
                />
                <div :if={permission.data.role} class="flex items-center gap-x-3">
                  <div class="size-8 flex items-center justify-center rounded-full bg-blue-600 text-xs text-gray-100 focus:outline-none">
                    role
                  </div>
                  <div class="flex flex-col items-start justify-center">
                    <div>
                      {permission.data.role.name}
                    </div>
                    <div class="text-alpha-64 text-xs">
                      {permission.data.role.description}
                    </div>
                  </div>
                </div>
              </div>

              <label class="col-span-1 flex items-center align-text-bottom">
                <input
                  type="checkbox"
                  name={"#{@step_form.name}[permission_drop][]"}
                  value={permission.index}
                  class="hidden"
                />
                <div class="bg-alpha-4 size-6 flex items-center justify-center rounded">
                  <.icon name="hero-x-mark-mini" class="h-5 w-5 align-bottom text-gray-900" />
                </div>
              </label>
            </div>
          </.inputs_for>
        </div>
      </div>

      <div class="flex gap-x-2">
        <.button
          type="button"
          variant="outline"
          data-testid="add-user-approver"
          phx-click={
            JS.push("select_step_id", value: %{step_id: @step_form.data.id})
            |> show_modal("add-user-modal")
          }
        >
          <div class="flex items-center gap-x-2">
            <.icon name="hero-plus-mini" class="h-5 w-5" /> Add user
          </div>
        </.button>

        <.button
          type="button"
          variant="outline"
          data-testid="add-role-approver"
          phx-click={
            JS.push("select_step_id", value: %{step_id: @step_form.data.id})
            |> show_modal("add-role-modal")
          }
        >
          <div class="flex items-center gap-x-2">
            <.icon name="hero-plus-mini" class="h-5 w-5" /> Add role
          </div>
        </.button>
      </div>
    </div>
    """
  end

  defp action(%{source_module: Step.ConditionAction} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-4">
      <.input
        field={@action_form[:condition]}
        label="Expression"
        tooltip="Expression to evaluate if workflow should continue, if evaluated as true workflow will continue. You can use the input, output from previous steps, and basic operators like ==, !=, >, <, >=, <=, &&, ||, not."
        phx-debounce
      />
      <.input
        field={@action_form[:when_false]}
        type="select"
        options={Ecto.Enum.values(Devhub.Workflows.Schemas.Step.ConditionAction, :when_false)}
        label="When false, mark workflow as"
        phx-debounce
      />
    </div>
    """
  end

  defp action(%{source_module: Step.QueryAction} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-4">
      <.select_with_search
        id={@action_form.id <> "-credential-search"}
        form={@action_form}
        label="Database user"
        selected={
          Enum.find_value(@credentials, &(&1.id == @action_form.data.credential_id && &1.name))
        }
        field={:credential_id}
        search_field={:credential_search}
        search_fun={
          fn search ->
            Enum.filter(@credentials, &String.contains?(String.downcase(&1.name), search))
          end
        }
      >
        <:item :let={credential}>
          <div
            data-testid={credential.id <> "-option"}
            class="flex w-full items-center justify-between"
          >
            <div class="flex flex-col items-start gap-y-1">
              <div>{credential.username}</div>
              <div class="text-alpha-64 text-xs">{credential.reviews_required} reviews required</div>
            </div>
            <div class="flex flex-col items-end gap-y-1">
              <div>{credential.database}</div>
              <div class="text-alpha-64 text-xs">{credential.group}</div>
            </div>
          </div>
        </:item>
      </.select_with_search>
      <.input field={@action_form[:query]} type="textarea" label="Query to run" phx-debounce />
      <.input field={@action_form[:timeout]} label="Timeout (seconds)" phx-debounce />
    </div>
    """
  end

  defp action(%{source_module: Step.SlackAction} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-4">
      <.input field={@action_form[:slack_channel]} label="Slack channel" phx-debounce />
      <.input field={@action_form[:message]} type="textarea" label="Message" phx-debounce />
      <.input field={@action_form[:link_text]} label="Link text" phx-debounce />
    </div>
    """
  end

  defp action(%{source_module: Step.SlackReplyAction} = assigns) do
    reply_to_steps =
      assigns.changeset.data.steps
      |> Enum.filter(&(&1.action.__struct__ == Step.SlackAction and &1.order < assigns.step_form.data.order))
      |> Enum.map(& &1.name)

    assigns = assign(assigns, reply_to_steps: reply_to_steps)

    ~H"""
    <div class="flex flex-col gap-y-4">
      <.input
        field={@action_form[:reply_to_step_name]}
        label="Reply to step"
        type="select"
        options={@reply_to_steps}
        phx-debounce
      />
      <.input field={@action_form[:message]} type="textarea" label="Message" phx-debounce />
    </div>
    """
  end
end
