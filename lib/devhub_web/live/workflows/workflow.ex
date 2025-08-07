defmodule DevhubWeb.Live.Workflows.Workflow do
  @moduledoc false
  use DevhubWeb, :live_view

  use LiveSync,
    subscription_key: :organization_id,
    watch: [:runs]

  import DevhubWeb.Components.Workflows.Status

  alias Devhub.Workflows

  def mount(%{"id" => id}, _session, socket) do
    %{organization: organization} = socket.assigns
    {:ok, workflow} = Workflows.get_workflow(id: id, organization_id: organization.id)

    inputs = Enum.map_join(workflow.inputs, ",\n", &~s(    "#{&1.key}": "#{&1.type}"))

    api_instructions = """
    curl #{DevhubWeb.Endpoint.url()}/api/v1/workflows/#{workflow.id}/run \\
      -H "x-api-key: dh_xxx" \\
      --json '{\n#{inputs}\n  }'
    """

    socket
    |> assign(
      page_title: "Devhub",
      workflow: workflow,
      api_instructions: api_instructions,
      breadcrumbs: [%{title: "Workflows", path: ~p"/workflows"}, %{title: workflow.name}]
    )
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    filter = params["filter"] || "pending"
    runs = Workflows.list_runs(socket.assigns.workflow.id, filters: [status: filter])

    socket |> assign(runs: runs, filter: filter) |> noreply()
  end

  def sync(:runs, updated, socket) do
    runs = Devhub.Repo.preload(updated, :triggered_by_user)
    assign(socket, runs: runs)
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header title={@workflow.name}>
        <:actions>
          <.link :if={@permissions.super_admin} navigate={~p"/workflows/#{@workflow.id}/edit"}>
            <.icon name="hero-cog-6-tooth" class="size-6" />
          </.link>
          <.button phx-click={show_modal("run-workflow")} data-testid="run-workflow">
            Run workflow
          </.button>
          <div class="bg-alpha-4 divide-alpha-16 border-alpha-16 z-10 flex divide-x rounded border text-sm">
            <.link
              patch={~p"/workflows/#{@workflow.id}"}
              class={"#{@filter == "pending" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
            >
              Pending
            </.link>
            <.link
              patch={~p"/workflows/#{@workflow.id}?filter=all"}
              class={"#{@filter == "all" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
            >
              All runs
            </.link>
          </div>
        </:actions>
      </.page_header>

      <.runs_list workflow={@workflow} runs={@runs} />
    </div>

    <.modal id="run-workflow" size="medium">
      <div>
        <div class="mb-2 text-center">
          <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-blue-200">
            <.icon name="hero-arrow-path-rounded-square" class="size-6 text-blue-800" />
          </div>
          <div class="mt-1 text-center">
            <h3 class="text-base font-semibold text-gray-900">
              Run workflow
            </h3>
          </div>
        </div>
      </div>
      <.form
        :let={f}
        for={%{}}
        phx-submit={JS.push("run_workflow") |> hide_modal("run-workflow")}
        data-testid="run-workflow"
      >
        <div class="flex flex-col gap-y-4">
          <div :for={input <- @workflow.inputs}>
            <.input label={input.key} field={f[input.key]} />
            <p :if={input.description} class="text-alpha-64 mt-1 text-xs">
              {input.description}
            </p>
          </div>
        </div>
        <div class="mt-4 grid grid-cols-2 gap-4">
          <.button
            type="button"
            variant="secondary"
            phx-click={JS.exec("data-cancel", to: "#run-workflow")}
            aria-label={gettext("close")}
          >
            Cancel
          </.button>
          <.button type="submit" variant="primary">Run</.button>
        </div>
      </.form>

      <div>
        <div class="my-6 text-center text-sm text-gray-500">
          &#8212; or run through the API &#8212;
        </div>
        <div class="bg-surface-3 rounded p-4">
          <div class="overflow-x-scroll">
            <pre class="break-all text-xs">{@api_instructions}</pre>
          </div>
        </div>
      </div>
    </.modal>
    """
  end

  def handle_event("run_workflow", params, socket) do
    params = Map.put(params, "triggered_by_user_id", socket.assigns.user.id)

    case Workflows.run_workflow(socket.assigns.workflow, params) do
      {:ok, run} ->
        socket
        |> push_navigate(to: ~p"/workflows/#{socket.assigns.workflow.id}/runs/#{run.id}")
        |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to run workflow") |> noreply()
    end
  end

  defp runs_list(assigns) do
    ~H"""
    <div
      :if={Enum.empty?(@runs)}
      class="border-alpha-8 rounded-lg border-2 border-dashed p-12 text-center"
    >
      <.icon name="hero-arrow-path-rounded-square" class="size-12 text-alpha-64" />
      <h3 class="my-3 text-base font-semibold text-gray-900">All runs have completed</h3>
      <p class="text-sm text-gray-500">
        <.link_button patch={~p"/workflows/#{@workflow.id}?filter=all"}>
          Show all runs
        </.link_button>
      </p>
    </div>
    <ul role="list" class="divide-alpha-8 bg-surface-1 divide-y rounded-lg">
      <li :for={run <- @runs} class="hover:bg-alpha-4">
        <div class="flex items-center">
          <div class="flex min-w-0 flex-1 items-center justify-between gap-x-4">
            <.link
              navigate={~p"/workflows/#{@workflow.id}/runs/#{run.id}"}
              class="flex h-full w-full items-center justify-between p-4"
            >
              <div class="truncate">
                <div class="mb-3 flex flex-col">
                  <div>
                    <div class="flex gap-x-1 truncate text-left text-gray-600">
                      <span class="text-alpha-64">
                        Triggered by:
                      </span>

                      <span :if={not is_nil(run.triggered_by_user)}>
                        {run.triggered_by_user.name || run.triggered_by_user.email}
                      </span>
                      <span :if={is_nil(run.triggered_by_user)}>
                        API
                      </span>
                    </div>
                  </div>
                  <div :for={{key, value} <- run.input}>
                    <div class="flex gap-x-1 truncate text-left text-gray-600">
                      <span class="text-alpha-64">{key}:</span> {value}
                    </div>
                  </div>
                </div>
                <div class="mt-1 flex">
                  <div class="flex items-center text-xs text-gray-600">
                    <format-date date={run.inserted_at} format="relative" />
                  </div>
                </div>
              </div>
              <div class="ml-5 flex flex-shrink-0 gap-x-1">
                <.status status={run.status} />
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
