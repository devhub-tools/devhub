defmodule DevhubWeb.Live.TerraDesk.WorkspaceSettings do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Agents
  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Google
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Workspace
  alias Devhub.Utils
  alias DevhubPrivate.Live.TerraDesk.Components.WorkspacePermissions

  def mount(params, _session, socket) do
    organization = socket.assigns.organization

    {workspace, breadcrumbs} =
      with %{"id" => id} <- params,
           {:ok, workspace} <-
             TerraDesk.get_workspace([id: id, organization_id: organization.id],
               preload: [permissions: [:role, organization_user: :user]]
             ) do
        {workspace, [%{title: workspace.name, path: ~p"/terradesk/workspaces/#{workspace.id}"}, %{title: "Settings"}]}
      else
        _not_found ->
          {%Workspace{
             organization_id: organization.id,
             name: "New workspace",
             permissions: [],
             secrets: [],
             env_vars: [],
             workload_identity: nil,
             repository: nil
           }, [%{title: "New workspace"}]}
      end

    workspace = Utils.sort_permissions(workspace)

    agent_options = Enum.map(Agents.list(organization.id), &{&1.name, &1.id})

    repository_options =
      organization.id
      |> GitHub.list_repositories()
      |> Enum.filter(& &1.enabled)
      |> Enum.map(&{"#{&1.owner}/#{&1.name}", &1.id})

    socket
    |> assign(
      page_title: "#{workspace.name} | Devhub",
      agent_options: agent_options,
      repository_options: repository_options,
      workspace: workspace,
      changeset: Workspace.changeset(workspace, %{}),
      claims: Google.workload_identity_claims(workspace.id),
      breadcrumbs: breadcrumbs
    )
    |> ok()
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
          <.link_button
            :if={@workspace.id}
            navigate={~p"/terradesk/workspaces/#{@workspace.id}"}
            variant="secondary"
          >
            Done
          </.link_button>
          <.link_button :if={is_nil(@workspace.id)} navigate={~p"/terradesk"} variant="secondary">
            Cancel
          </.link_button>
          <.button phx-click="save">
            Save
          </.button>
        </:actions>
      </.page_header>

      <.form :let={f} for={@changeset} phx-change="update_changeset">
        <div class="flex flex-col gap-y-4">
          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Workspace configuration</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                This information allows you to define the basic configuration of your workspace.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-4">
              <.input field={f[:name]} label="Workspace name" />
              <.input
                field={f[:repository_id]}
                type="select"
                prompt="Choose a repository"
                options={@repository_options}
                label="GitHub repository"
              />
              <.input field={f[:init_args]} label="Args to pass to `terraform init`" />
              <.input field={f[:path]} label="Path to workspace (defaults to root)" />
              <.input
                type="select"
                field={f[:agent_id]}
                label={(Devhub.cloud_hosted?() && "Agent (required)") || "Agent"}
                prompt="None"
                options={@agent_options}
              />
              <.input field={f[:required_approvals]} label="Required approvals for applies" />
              <div class="mt-3">
                <.input
                  type="checkbox"
                  field={f[:run_plans_automatically]}
                  label="Run plans automatically on pushes and PRs"
                />
              </div>
            </div>
          </div>

          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Job configuration</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                All commands are run with a kubernetes job, this section allows you to configure options for the jobs.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-4">
              <.input
                field={f[:docker_image]}
                label="Docker image"
                tooltip="The docker image to use, for example hashicorp/terraform:1.10 or ghcr.io/opentofu/opentofu:1.9.0"
              />
              <.input
                field={f[:cpu_requests]}
                label="cpu request"
                tooltip="How much cpu should be requested for the pod scheduled by the job, see kubernetes docs for allowable values."
              />
              <.input
                field={f[:memory_requests]}
                label="memory request"
                tooltip="How much memory should be requested for the pod scheduled by the job, see kubernetes docs for allowable values."
              />
            </div>
          </div>

          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Secret variables</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                This section allows you to manage secret
                <span class="text-blue-700">terraform variables</span>
                for your workspace, such as API keys or passwords.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-4">
              <div>
                <.inputs_for :let={secret} field={f[:secrets]}>
                  <input type="hidden" name="workspace[secret_sort][]" value={secret.index} />
                  <div class="mb-1 flex items-center gap-x-4">
                    <div class="flex-1">
                      <.input field={secret[:name]} autocomplete="off" />
                    </div>

                    <div class="flex-1">
                      <.input
                        type="password"
                        placeholder="hidden"
                        field={secret[:value]}
                        value={secret.source.changes[:value]}
                        autocomplete="off"
                      />
                    </div>
                    <label class="col-span-1 flex items-center align-text-bottom">
                      <input
                        type="checkbox"
                        name="workspace[secret_drop][]"
                        value={secret.index}
                        class="hidden"
                      />
                      <div class="bg-alpha-4 size-6 mt-2 flex items-center justify-center rounded-md">
                        <.icon name="hero-x-mark-mini" class="size-5 align-bottom text-gray-900" />
                      </div>
                    </label>
                  </div>
                </.inputs_for>
              </div>

              <label class="flex h-8 w-fit items-center whitespace-nowrap rounded-md p-2 text-sm font-bold text-blue-800 ring-1 ring-inset ring-blue-300 transition-colors disabled:pointer-events-none disabled:opacity-50">
                <input type="checkbox" name="workspace[secret_sort][]" class="hidden" />
                <div class="flex items-center gap-x-2">
                  <.icon name="hero-plus-mini" class="size-5" /> Add secret variable
                </div>
              </label>
            </div>
          </div>

          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Environment variables</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                This section allows you to manage environment variables for your terraform workspace. Do not include sensitive information here as it is stored in plain text.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-4">
              <div>
                <.inputs_for :let={env_var} field={f[:env_vars]}>
                  <input type="hidden" name="workspace[env_var_sort][]" value={env_var.index} />
                  <div class="mb-1 flex items-center gap-x-4">
                    <div class="flex-1">
                      <.input field={env_var[:name]} autocomplete="off" />
                    </div>

                    <div class="flex-1">
                      <.input field={env_var[:value]} autocomplete="off" />
                    </div>
                    <label class="col-span-1 align-text-bottom">
                      <input
                        type="checkbox"
                        name="workspace[env_var_drop][]"
                        value={env_var.index}
                        class="hidden"
                      />
                      <div class="bg-alpha-4 size-6 mt-2 flex items-center justify-center rounded-md">
                        <.icon name="hero-x-mark-mini" class="size-5 align-bottom text-gray-900" />
                      </div>
                    </label>
                  </div>
                </.inputs_for>
              </div>

              <label class="flex h-8 w-fit items-center whitespace-nowrap rounded-md p-2 text-sm font-bold text-blue-800 ring-1 ring-inset ring-blue-300 transition-colors disabled:pointer-events-none disabled:opacity-50">
                <input type="checkbox" name="workspace[env_var_sort][]" class="hidden" />
                <div class="flex items-center gap-x-2">
                  <.icon name="hero-plus-mini" class="size-5" /> Add environment variable
                </div>
              </label>
            </div>
          </div>

          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">
                Google workload identity
              </h2>
              <p class="text-alpha-64 mt-1 text-sm">
                Configure workload identity for your terraform workspace to authenticate with Google Cloud services.
              </p>
            </div>

            <div class="col-span-5">
              <.inputs_for :let={wif} field={f[:workload_identity]}>
                <.input type="toggle" field={wif[:enabled]} label="Enabled" />

                <div :if={wif[:enabled].value} class="mt-6 flex flex-col gap-y-4">
                  <.input
                    field={wif[:service_account_email]}
                    label="Service Account Email"
                    autocomplete="off"
                  />

                  <div>
                    <.input field={wif[:provider]} label="Workload Provider Id" autocomplete="off" />
                    <div class="text-alpha-64 text-wrap mt-1 text-xs">
                      projects/<span class="text-blue-700">PROJECT_NUMBER</span>/locations/global/workloadIdentityPools/<span class="text-blue-700">POOL</span>/providers/<span class="text-blue-700">PROVIDER</span>
                    </div>
                  </div>

                  <div>
                    <h1 class="text-alpha-64 block text-xs uppercase">
                      Issuer
                    </h1>
                    <div class="text-alpha-88 bg-alpha-4 ring-alpha-16 mt-2 block overflow-x-auto rounded p-2 text-sm ring-1">
                      {Application.get_env(:devhub, :issuer)}
                    </div>
                  </div>

                  <div>
                    <h1 class="text-alpha-64 block text-xs uppercase">
                      Token claims
                    </h1>
                    <div class="text-alpha-88 bg-alpha-4 ring-alpha-16 mt-2 block overflow-x-auto rounded p-2 text-sm ring-1">
                      <pre><%= @claims %></pre>
                    </div>
                  </div>
                </div>
              </.inputs_for>
            </div>
          </div>

          <.live_component
            :if={Code.ensure_loaded?(WorkspacePermissions)}
            module={WorkspacePermissions}
            id="workspace-permissions"
            workspace_id={@workspace.id}
            form={f}
          />
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("update_changeset", %{"workspace" => params}, socket) do
    # clear out values if empty so we don't override the secret value if it wasn't updated
    params =
      if Map.has_key?(params, "secrets") do
        %{
          params
          | "secrets" =>
              Map.new(params["secrets"], fn {k, secret} ->
                if secret["value"] == "" do
                  {k, Map.delete(secret, "value")}
                else
                  {k, secret}
                end
              end)
        }
      else
        params
      end

    params = Map.delete(params, "_unused_repository_id")

    # allowing empty for changeset validation
    repository_ids = ["" | Enum.map(socket.assigns.repository_options, &elem(&1, 1))]

    if params["repository_id"] in repository_ids do
      changeset = socket.assigns.workspace |> Workspace.changeset(params) |> Map.put(:action, :update)
      socket |> assign(changeset: changeset, params: params) |> noreply()
    else
      socket
      |> put_flash(:error, "Invalid repository selected.")
      |> noreply()
    end
  end

  def handle_event("save", _params, socket) do
    case TerraDesk.insert_or_update_workspace(socket.assigns.workspace, socket.assigns.params) do
      {:ok, workspace} ->
        socket
        |> assign(workspace: workspace, changeset: Workspace.changeset(workspace, %{}))
        |> put_flash(:info, "Settings saved.")
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(changeset: changeset)
        |> put_flash(:error, "Failed to save settings.")
        |> noreply()
    end
  end
end
