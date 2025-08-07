defmodule DevhubWeb.Live.Workflows.Run do
  @moduledoc false
  use DevhubWeb, :live_view

  use LiveSync,
    subscription_key: :organization_id,
    watch: [:run]

  import DevhubWeb.Components.Workflows.Status

  alias Devhub.Permissions
  alias Devhub.QueryDesk
  alias Devhub.Users
  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Step.ApiAction

  def mount(%{"run_id" => id}, _session, socket) do
    %{organization: organization} = socket.assigns
    {:ok, run} = Workflows.get_run(id: id, organization_id: organization.id)
    run = Workflows.preload_run(run)

    socket
    |> assign(
      page_title: "Devhub",
      run: run,
      breadcrumbs: [
        %{title: "Workflows", path: ~p"/workflows"},
        %{title: run.workflow.name, path: ~p"/workflows/#{run.workflow.id}"},
        %{title: "Run"}
      ]
    )
    |> ok()
  end

  def sync(:run, updated, socket) do
    run = socket.assigns.run

    updated = %{updated | steps: (Enum.empty?(updated.steps) && run.steps) || updated.steps}
    run = Workflows.preload_run(updated)
    assign(socket, run: run)
  end

  def render(assigns) do
    next_step_id =
      case next_step(assigns.run) do
        %{workflow_step_id: id} -> id
        nil -> nil
      end

    assigns = assign(assigns, next_step_id: next_step_id)

    ~H"""
    <div class="text-sm">
      <.page_header>
        <:header>
          <div class="flex min-w-0 gap-x-4">
            <div class="min-w-0 flex-auto">
              <p class="text-2xl font-bold">
                {@run.workflow.name}
              </p>
              <p class="mt-1 flex text-xs text-gray-600">
                <format-date date={@run.inserted_at} format="relative-datetime" />
              </p>
            </div>
          </div>
        </:header>
        <:actions>
          <copy-button
            icon="link"
            value={"#{DevhubWeb.Endpoint.url()}/workflows/#{@run.workflow.id}/runs/#{@run.id}"}
          />
          <.status status={@run.status} />
          <.button
            :if={@run.status in [:in_progress, :waiting_for_approval]}
            phx-click="cancel"
            variant="destructive"
          >
            Cancel
          </.button>
        </:actions>
      </.page_header>
      <div class="bg-surface-1 relative flex flex-col gap-y-4 rounded-lg p-4">
        <div :if={is_struct(@run.triggered_by_user) or is_struct(@run.triggered_by_linear_issue)}>
          <p class="mb-3 text-lg font-medium">Triggered by</p>
          <.user_block :if={@run.triggered_by_user} user={@run.triggered_by_user} />
          <div :if={@run.triggered_by_linear_issue} class="flex items-center gap-x-2">
            <.link
              href={@run.triggered_by_linear_issue.url}
              target="_blank"
              class="flex items-center justify-end gap-x-2"
            >
              <.icon name="devhub-linear" class="size-6 fill-[#24292F]" />
              <div class="">
                <p>
                  {@run.triggered_by_linear_issue.identifier}
                </p>

                <p class="text-wrap mt-1 text-xs text-gray-400">
                  {@run.triggered_by_linear_issue.title}
                </p>
              </div>
            </.link>
          </div>
        </div>
        <div :if={map_size(@run.input) > 0}>
          <p class="mb-3 text-lg font-medium">Inputs</p>
          <div class="flex flex-col">
            <div :for={{key, value} <- @run.input}>
              <div class="flex gap-x-1 truncate text-left text-gray-600">
                <%= if is_binary(value) and String.starts_with?(value, "https://") do %>
                  <span class="text-alpha-64">{key}:</span><.link
                    href={value}
                    target="_blank"
                    class="text-blue-600"
                  >{value}</.link>
                <% else %>
                  <span class="text-alpha-64">{key}:</span> {value}
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="my-2 flex w-full items-center justify-center">
        <.icon name="hero-arrow-down-mini" class="size-10 text-alpha-32" />
      </div>
      <.step
        :for={step <- @run.steps}
        organization_user={@organization_user}
        run={@run}
        step={step}
        next_step_id={@next_step_id}
      />
      <div class="my-2 flex w-full items-center justify-center">
        <.icon
          :if={@run.status == :completed}
          name="hero-check-circle"
          class="size-10 text-green-400"
        />
        <.icon
          :if={@run.status == :failed}
          name="hero-exclamation-circle"
          class="size-10 text-red-400"
        />
        <.icon :if={@run.status == :canceled} name="hero-x-circle" class="size-10 text-alpha-32" />
        <.icon
          :if={@run.status not in [:completed, :failed, :canceled]}
          name="hero-check-circle"
          class="size-10 text-alpha-32"
        />
      </div>
    </div>
    """
  end

  def handle_event("approve", params, socket) do
    %{organization_user: organization_user, run: run} = socket.assigns

    step = next_step(run)

    cond do
      not Permissions.can?(:approve, step.workflow_step, organization_user) ->
        {:noreply, socket}

      not socket.assigns.mfa_enabled? ->
        {:ok, run} = Workflows.approve_step(run, step, organization_user)
        socket |> assign(run: run) |> noreply()

      is_nil(params["authenticatorData"]) ->
        socket |> start_passkey_authentication(socket.assigns.user, "approve") |> noreply()

      true ->
        case Users.authenticate_passkey(params, socket.assigns.challenge, socket.assigns.allow_credentials) do
          :ok ->
            {:ok, run} = Workflows.approve_step(run, step, organization_user)
            socket |> assign(run: run) |> noreply()

          {:error, _error} ->
            socket |> put_flash(:error, "Passkey verification failed.") |> noreply()
        end
    end
  end

  def handle_event("cancel", _params, socket) do
    {:ok, run} = Workflows.cancel_run(socket.assigns.run)
    socket |> assign(run: run) |> noreply()
  end

  defp step(assigns) do
    ~H"""
    <div class={[
      "bg-surface-1 relative rounded-lg p-4",
      (@step.status == :pending and @step.workflow_step_id != @next_step_id) && "opacity-50"
    ]}>
      <.action
        organization_user={@organization_user}
        step={@step}
        next_step_id={@next_step_id}
        run={@run}
        type={
          PolymorphicEmbed.get_polymorphic_type(Devhub.Workflows.Schemas.Step, :action, @step.action)
        }
      />
    </div>

    <div class="my-2 flex w-full items-center justify-center">
      <.icon name="hero-arrow-down-mini" class="size-10 text-alpha-32" />
    </div>
    """
  end

  defp action(%{type: :api} = assigns) do
    ~H"""
    <div>
      <div class="mb-6 flex items-start justify-between">
        <div class="flex flex-col">
          <p class="mb-3 text-lg font-medium">API</p>
          <div :if={@step.name} class="flex gap-x-1 truncate text-left text-gray-600">
            <span class="text-alpha-64">Name:</span> {@step.name}
          </div>
          <div :if={@step.condition} class="flex flex-col gap-x-1 truncate text-left text-gray-600">
            <span class="text-alpha-64">Run if:</span>
            <code class="bg-surface-3 my-1 max-h-48 overflow-auto break-all rounded p-4">
              {@step.condition}
            </code>
          </div>
          <div class="flex gap-x-1 truncate text-left text-gray-600">
            <span class="text-alpha-64">Endpoint:</span> {@step.action.endpoint}
          </div>
          <div class="flex gap-x-1 truncate text-left text-gray-600">
            <span class="text-alpha-64">Body:</span>
            {@step.action.body &&
              Enum.reduce(
                @run.input,
                @step.action.body,
                fn {key, value}, acc ->
                  String.replace(acc, "${#{key}}", to_string(value))
                end
              )}
          </div>
        </div>

        <div :if={@step.status != :pending} class="flex items-center gap-x-2">
          <div><.status status={@step.status} /></div>
        </div>
      </div>

      <p class="mt-3 mb-1 font-medium">Result</p>
      <div :if={@step.status != :pending}>
        <div class="flex gap-x-1 text-left text-gray-600">
          <span class="text-alpha-64">Status code:</span> {@step.output["status_code"]}
        </div>
        <div class="bg-surface-1 mt-2 max-h-48 overflow-auto rounded p-4 text-xs">
          <pre>{ApiAction.format_result(@step.output)}</pre>
        </div>
      </div>
    </div>
    """
  end

  defp action(%{type: :approval} = assigns) do
    ~H"""
    <div>
      <div class="mb-6 flex items-start justify-between">
        <p class="mb-3 text-lg font-medium">Approval required</p>

        <div :if={@step.condition} class="flex flex-col gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Run if:</span>
          <code class="bg-surface-3 my-1 max-h-48 overflow-auto break-all rounded p-4">
            {@step.condition}
          </code>
        </div>

        <div class="flex items-center gap-x-2">
          <div class="flex flex-col items-end">
            <p class="text-xs">
              {length(@step.approvals)} / {@step.action.reviews_required}
            </p>
            <p class="text-alpha-64 text-xs">
              approvals
            </p>
          </div>
          <.button
            :if={
              @step.workflow_step_id == @next_step_id and
                Permissions.can?(:approve, @step.workflow_step, @organization_user)
            }
            id={"approve-#{@step.workflow_step_id}"}
            phx-hook="Passkey"
            phx-click="approve"
            disabled={already_approved(@step, @organization_user.id)}
          >
            Approve
          </.button>
          <div :if={@step.status == :succeeded}>
            <.status status={:approved} />
          </div>
        </div>
      </div>

      <p class="mt-4 mb-2 font-medium">Approvers</p>
      <div
        :for={permission <- @step.workflow_step.permissions}
        :if={@step.status != :succeeded}
        class="ring-alpha-16 mb-2 flex items-center justify-between rounded p-4 ring-1"
      >
        <.user_block :if={permission.organization_user} user={permission.organization_user.user} />
        <div :if={permission.role} class="flex items-center gap-x-3">
          <div class="size-8 flex items-center justify-center rounded-full bg-blue-600 text-xs text-gray-100 focus:outline-none">
            role
          </div>
          <div class="flex flex-col items-start justify-center">
            <div>
              {permission.role.name}
            </div>
            <div class="text-alpha-64 text-xs">
              {permission.role.description}
            </div>
          </div>
        </div>
        <div :if={
          approval =
            Enum.find(
              @step.approvals,
              &(&1.organization_user_id == permission.organization_user_id)
            )
        }>
          <format-date date={approval.approved_at} format="relative-datetime" />
          <.icon name="hero-check-circle" class="size-6 text-green-400" />
        </div>
      </div>
      <div
        :for={approval <- @step.approvals}
        :if={@step.status == :succeeded}
        class="ring-alpha-16 mb-2 flex items-center justify-between rounded p-4 ring-1"
      >
        <.user_block user={approval.organization_user.user} />
        <div>
          <format-date date={approval.approved_at} format="relative-datetime" />
          <.icon name="hero-check-circle" class="size-6 text-green-400" />
        </div>
      </div>
    </div>
    """
  end

  defp action(%{type: :condition} = assigns) do
    label =
      if assigns.step.output["eval"] == true,
        do: "Workflow allowed to continue",
        else: "Workflow stopped and marked as #{assigns.step.action.when_false}"

    color = if assigns.step.output["eval"] == true, do: "green", else: "red"

    assigns = assign(assigns, label: label, color: color)

    ~H"""
    <div class="flex items-start justify-between">
      <div class="flex flex-col">
        <p class="mb-3 text-lg font-medium">Condition</p>
        <div :if={@step.name} class="flex gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Name:</span> {@step.name}
        </div>
        <div :if={@step.condition} class="flex flex-col gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Run if:</span>
          <code class="bg-surface-3 my-1 max-h-48 overflow-auto break-all rounded p-4">
            {@step.condition}
          </code>
        </div>
        <div class="flex gap-x-4">
          <div class="mb-4 flex flex-col gap-x-1 truncate text-left text-gray-600">
            <span class="text-alpha-64">Condition:</span>
            <code class="bg-surface-3 max-h-48 overflow-auto break-all rounded p-4">
              {@step.action.condition}
            </code>
            <div class="text-alpha-64 mt-1 text-xs">
              {@step.workflow_step.action.condition}
            </div>
          </div>
          <div
            :if={not is_nil(@step.output["eval"])}
            class="mb-4 flex flex-col gap-x-1 truncate text-left text-gray-600"
          >
            <span class="text-alpha-64">Evaluated:</span>
            <code class="bg-surface-3 max-h-48 overflow-auto break-all rounded p-4">
              {@step.output["eval"]}
            </code>
          </div>
        </div>

        <div :if={@step.status == :succeeded} class="flex">
          <.badge label={@label} color={@color} />
        </div>
      </div>

      <div :if={@step.status != :pending} class="flex items-center gap-x-2">
        <div><.status status={@step.status} /></div>
      </div>
    </div>
    """
  end

  defp action(%{type: :query} = assigns) do
    %{credential: credential} = Devhub.Repo.preload(assigns.step.action, credential: :database)

    credential_name =
      if credential.database.group do
        "#{credential.username} - #{credential.database.name} (#{credential.database.group})"
      else
        "#{credential.username} - #{credential.database.name}"
      end

    result =
      if assigns.step.output do
        rows =
          Enum.map(assigns.step.output["rows"] || [], fn row ->
            Enum.map(row, &QueryDesk.format_field/1)
          end)

        assigns.step.output |> Map.put("rows", rows) |> Jason.encode!()
      end

    assigns = assign(assigns, credential_name: credential_name, adapter: credential.database.adapter, result: result)

    ~H"""
    <div>
      <div class="mb-6 flex items-start justify-between">
        <div class="flex flex-col">
          <p class="mb-3 text-lg font-medium">Query</p>
          <div :if={@step.name} class="flex gap-x-1 truncate text-left text-gray-600">
            <span class="text-alpha-64">Name:</span> {@step.name}
          </div>
          <div :if={@step.condition} class="flex flex-col gap-x-1 truncate text-left text-gray-600">
            <span class="text-alpha-64">Run if:</span>
            <code class="bg-surface-3 my-1 max-h-48 overflow-auto break-all rounded p-4">
              {@step.condition}
            </code>
          </div>
          <div class="flex gap-x-1 truncate text-left text-gray-600">
            <span class="text-alpha-64">Database user:</span> {@credential_name}
          </div>
          <span class="text-alpha-64">Query:</span>
          <div class="bg-surface-2 mt-1 overflow-auto rounded p-4 text-sm">
            <pre
              :if={not is_nil(@step.query)}
              id={@step.workflow_step_id <> "-query"}
              phx-hook="SqlHighlight"
              data-query={@step.query.query}
              data-adapter={@adapter}
            />
            <pre
              :if={is_nil(@step.query)}
              id={@step.workflow_step_id <> "-query"}
              phx-hook="SqlHighlight"
              data-query={QueryDesk.replace_query_variables(@step.action.query, @run.input)}
              data-adapter={@adapter}
            />
          </div>
        </div>

        <div :if={@step.status != :pending} class="flex items-center gap-x-2">
          <format-date
            :if={not is_nil(@step.query)}
            date={@step.query.executed_at}
            format="relative-datetime"
          />
          <div><.status status={@step.status} /></div>
        </div>
      </div>

      <div
        :if={@step.status != :pending and is_nil(@step.output["error"])}
        class="border-alpha-8 overflow-auto rounded-lg border"
      >
        <data-table id={@step.workflow_step_id <> "-query-result"} data={@result} />
      </div>
      <div :if={not is_nil(@step.output["error"])} class="bg-surface-1 rounded p-4">
        {@step.output["error"]}
      </div>
    </div>
    """
  end

  defp action(%{type: :slack} = assigns) do
    posted_at =
      with %{step: %{output: %{"timestamp" => timestamp}}} <- assigns,
           {unix, _rest} <- Integer.parse(timestamp),
           {:ok, posted_at} <- DateTime.from_unix(unix) do
        posted_at
      else
        _error -> nil
      end

    assigns = assign(assigns, posted_at: posted_at)

    ~H"""
    <div class="flex items-start justify-between">
      <div class="flex flex-col">
        <p class="mb-3 text-lg font-medium">Slack message</p>
        <div :if={@step.name} class="flex gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Name:</span> {@step.name}
        </div>
        <div :if={@step.condition} class="flex flex-col gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Run if:</span>
          <code class="bg-surface-3 my-1 max-h-48 overflow-auto break-all rounded p-4">
            {@step.condition}
          </code>
        </div>
        <div class="flex gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Slack channel:</span> {@step.action.slack_channel}
        </div>
        <div class="flex gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Message:</span> {@step.action.message}
        </div>
      </div>

      <div :if={@step.status != :pending} class="flex items-center gap-x-2">
        <format-date date={@posted_at} format="relative-datetime" />
        <div><.status status={@step.status} /></div>
      </div>
    </div>
    """
  end

  defp action(%{type: :slack_reply} = assigns) do
    posted_at =
      with %{step: %{output: %{"timestamp" => timestamp}}} <- assigns,
           {unix, _rest} <- Integer.parse(timestamp),
           {:ok, posted_at} <- DateTime.from_unix(unix) do
        posted_at
      else
        _error -> assigns.run.updated_at
      end

    assigns = assign(assigns, posted_at: posted_at)

    ~H"""
    <div class="flex items-start justify-between">
      <div class="flex flex-col">
        <p class="mb-3 text-lg font-medium">Slack reply</p>
        <div :if={@step.name} class="flex gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Name:</span> {@step.name}
        </div>
        <div :if={@step.condition} class="flex flex-col gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Run if:</span>
          <code class="bg-surface-3 my-1 max-h-48 overflow-auto break-all rounded p-4">
            {@step.condition}
          </code>
        </div>
        <div class="flex gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Reply to:</span> {@step.action.reply_to_step_name}
        </div>
        <div class="flex gap-x-1 truncate text-left text-gray-600">
          <span class="text-alpha-64">Message:</span> {@step.action.message}
        </div>
      </div>

      <div :if={@step.status != :pending} class="flex items-center gap-x-2">
        <format-date date={@posted_at} format="relative-datetime" />
        <div><.status status={@step.status} /></div>
      </div>
    </div>
    """
  end

  defp already_approved(%{approvals: approvals}, organization_user_id) do
    Enum.any?(approvals || [], &(&1.organization_user_id == organization_user_id))
  end

  defp already_approved(nil, _organization_user_id) do
    false
  end

  defp next_step(%{status: status} = run) when status in [:in_progress, :waiting_for_approval] do
    Enum.find(run.steps, &(&1.status == :pending))
  end

  defp next_step(_run), do: nil
end
