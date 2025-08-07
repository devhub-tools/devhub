defmodule DevhubWeb.Live.Settings.LinearSetup do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations
  alias Devhub.Integrations.Linear.Jobs.Import

  def mount(_params, _session, socket) do
    case Integrations.get_by(organization_id: socket.assigns.organization.id, provider: :linear) do
      {:ok, _integration} ->
        socket |> push_navigate(to: ~p"/settings/integrations/linear") |> ok()

      {:error, :integration_not_found} ->
        socket
        |> assign(
          page_title: "Devhub",
          step: 1,
          import_status: "Starting import",
          import_percentage: 0,
          import_started: false,
          breadcrumbs: [
            %{title: "Settings", path: ~p"/settings/integrations"},
            %{title: "Linear setup"}
          ]
        )
        |> ok()
    end
  end

  def render(%{step: 1} = assigns) do
    ~H"""
    <div>
      <.page_header title="Linear setup" subtitle="Register a Linear app to sync your data">
        <:actions>
          <.button phx-click="next_step" phx-value-step="2">
            Next
          </.button>
        </:actions>
      </.page_header>
      <div class="bg-surface-1 rounded-lg p-4">
        <div>
          Create a linear app at
          <.link_button
            href="https://linear.app/settings/api/applications/new"
            target="_blank"
            variant="text"
            size="sm"
          >
            https://linear.app/settings/api/applications/new
          </.link_button>
        </div>
        <copy-text label="Application name" value="Devhub" />
        <copy-text label="Developer name" value="Devhub" />
        <copy-text label="Developer URL" value="https://devhub.tools" />
        <copy-text label="Callback URL" value={DevhubWeb.Endpoint.url() <> "/auth/linear/callback"} />
        <copy-text label="Webhook URL" value={DevhubWeb.Endpoint.url() <> "/webhook/linear"} />
        <div class="text-alpha-64 mt-6 text-xs uppercase">Enable the following webhook events</div>
        <ul class="mt-1 ml-3 list-disc text-sm">
          <li>Issues</li>
          <li>Labels</li>
          <li>Projects</li>
          <li>Users</li>
        </ul>
      </div>
    </div>
    """
  end

  def render(%{import_started: false} = assigns) do
    ~H"""
    <.page_header title="Linear setup" subtitle="Register a Linear app to sync your data" />
    <div class="bg-surface-1 rounded-lg p-4">
      <.form :let={f} for={%{}} phx-submit="start_import" class="flex flex-col gap-y-4">
        <.input field={f[:access_token]} label="Access token" />
        <span class="text-alpha-64 -mt-2 text-xs">
          Click on "Create & copy token" next to "Developer token" and choose "Application".
        </span>
        <.input field={f[:webhook_secret]} label="Webhook signing secret" />
        <span class="text-alpha-64 -mt-2 text-xs">
          The webhook signing secret can be found inside edit application and will begin with <span class="font-bold">lin_wh_</span>.
        </span>
        <div>
          <.button type="submit">
            Import
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title="Linear setup" subtitle="Register a Linear app to sync your data" />
      <div :if={@import_percentage < 100} class="bg-surface-1 rounded-lg p-4">
        <h4 class="sr-only">Status</h4>
        <div class="flex items-center gap-x-1" data-testid="linear-import-status">
          <div class="size-4 ml-1"><.spinner /></div>
          <p class="text-alpha-64 text-sm font-medium">{@import_status}</p>
        </div>
        <div class="mt-3" aria-hidden="true">
          <div class="overflow-hidden rounded-full bg-gray-200">
            <div
              class="h-2 rounded-full bg-blue-600 transition-all duration-1000"
              data-testid="linear-import-percentage"
              style={"width: #{@import_percentage}%"}
            >
            </div>
          </div>
        </div>
      </div>

      <div :if={@import_percentage == 100} class="bg-surface-1 rounded-lg p-4">
        <h4 class="sr-only">Status</h4>
        <div class="flex items-center justify-between">
          <p class="text-alpha-64 text-sm font-medium">Your import is complete</p>
          <.link_button navigate={~p"/settings/integrations/linear"}>
            Done
          </.link_button>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("next_step", %{"step" => step}, socket) do
    socket |> assign(step: String.to_integer(step)) |> noreply()
  end

  def handle_event("start_import", params, socket) do
    %{
      provider: :linear,
      access_token: Jason.encode!(params),
      organization_id: socket.assigns.organization.id
    }
    |> Integrations.create()
    |> case do
      {:ok, integration} ->
        Phoenix.PubSub.subscribe(Devhub.PubSub, "linear_sync:#{socket.assigns.organization.id}")

        # sync 30 days quickly to provide feedback to user
        %{id: integration.id, days_to_sync: 30} |> Import.new() |> Oban.insert!()

        # sync 365 days with min priority
        %{id: integration.id, days_to_sync: 365} |> Import.new(priority: 9) |> Oban.insert!()

        socket |> assign(import_started: true) |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to start import") |> noreply()
    end
  end

  def handle_info({:import_status, details}, socket) do
    socket |> assign(import_status: details.message, import_percentage: details.percentage) |> noreply()
  end
end
