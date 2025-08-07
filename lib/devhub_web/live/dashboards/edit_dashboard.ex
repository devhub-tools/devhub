defmodule DevhubWeb.Live.Dashboards.EditDashboard do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Dashboards
  alias Devhub.Dashboards.Schemas.Dashboard
  alias Devhub.Dashboards.Schemas.Dashboard.Panel
  alias Devhub.Dashboards.Schemas.Dashboard.QueryPanel
  alias Devhub.QueryDesk
  alias Devhub.Utils
  alias DevhubPrivate.Live.QueryDesk.Components.DashboardPermissions

  def mount(%{"id" => dashboard_id}, _session, socket) do
    organization = socket.assigns.organization
    {:ok, dashboard} = Dashboards.get_dashboard(id: dashboard_id, organization_id: organization.id)

    dashboard = Utils.sort_permissions(dashboard)

    credentials = QueryDesk.list_credential_options(socket.assigns.organization_user)

    socket
    |> assign(
      page_title: "Devhub",
      dashboard: dashboard,
      changeset: Dashboard.changeset(dashboard, %{}),
      credentials: credentials,
      show_saved: false,
      breadcrumbs: [
        %{title: "Dashboards", path: ~p"/dashboards"},
        %{title: dashboard.name}
      ]
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header title={@dashboard.name}>
        <:actions>
          <p :if={@show_saved} class="flex items-center gap-x-1 text-green-500 transition-all">
            <.icon name="hero-check-circle" class="size-6" />Saved
          </p>
          <.button phx-click="add_panel" variant="outline">Add panel</.button>
          <.link_button navigate={~p"/dashboards/#{@dashboard.id}/view"}>
            Done
          </.link_button>
        </:actions>
      </.page_header>

      <.form :let={f} for={@changeset} phx-change="update">
        <div class="bg-surface-1 relative flex flex-col gap-y-4 rounded-lg p-4">
          <.input field={f[:name]} label="Dashboard name" phx-debounce />
          <.live_component
            :if={Code.ensure_loaded?(DashboardPermissions)}
            module={DashboardPermissions}
            id="dashboard-permissions"
            form={f}
          />
        </div>

        <div class="mt-4 grid grid-cols-2 gap-x-4">
          <.inputs_for :let={panel} field={f[:panels]}>
            <input type="hidden" name="dashboard[panel_sort][]" value={panel.index} />
            <.panel panel={panel} changeset={@changeset} credentials={@credentials} />
          </.inputs_for>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event(
        "update",
        %{"_target" => ["dashboard", "panels", _index, "details", "credential_search"], "dashboard" => params},
        socket
      ) do
    changeset = Dashboard.changeset(socket.assigns.dashboard, params)
    socket |> assign(changeset: changeset) |> noreply()
  end

  def handle_event("update", %{"dashboard" => params}, socket) do
    case Dashboards.update_dashboard(socket.assigns.dashboard, params) do
      {:ok, dashboard} ->
        changeset = Dashboard.changeset(dashboard, %{})

        with %{timer_ref: timer_ref} <- socket.assigns do
          Process.cancel_timer(timer_ref, async: true, info: false)
        end

        timer_ref = Process.send_after(self(), :saved, 500)

        socket
        |> assign(dashboard: dashboard, changeset: changeset, timer_ref: timer_ref)
        |> noreply()

      {:error, changeset} ->
        socket |> assign(changeset: changeset) |> noreply()
    end
  end

  def handle_event("add_panel", _params, socket) do
    existing_panels = Ecto.Changeset.get_field(socket.assigns.changeset, :panels)
    new_panels = [%Panel{details: %QueryPanel{}}]

    panels = Enum.concat(existing_panels, new_panels)

    changeset = Ecto.Changeset.put_change(socket.assigns.changeset, :panels, panels)

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  def handle_info(:saved, socket) do
    timer_ref = Process.send_after(self(), :remove_saved, 3_000)

    socket |> assign(show_saved: true, timer_ref: timer_ref) |> noreply()
  end

  def handle_info(:remove_saved, socket) do
    socket |> assign(show_saved: false) |> noreply()
  end

  defp panel(assigns) do
    ~H"""
    <div class="bg-surface-1 relative rounded-lg p-4">
      <label class="absolute top-2 right-2 cursor-pointer">
        <input type="checkbox" name="dashboard[panel_drop][]" value={@panel.index} class="hidden" />
        <span class="text-red-400">Remove panel</span>
      </label>

      <.polymorphic_embed_inputs_for :let={details_form} field={@panel[:details]} skip_hidden={true}>
        <div class="mb-4 flex flex-col gap-y-4">
          <.input field={@panel[:title]} label="Panel title" phx-debounce />

          <div>
            <p class="text-alpha-64 text-xs uppercase">Inputs</p>
            <.inputs_for :let={input} field={@panel[:inputs]}>
              <div class="flex w-full items-center gap-x-2">
                <input type="hidden" name={"#{@panel.name}[input_sort][]"} value={input.index} />
                <div class="flex-1">
                  <.input field={input[:key]} placeholder="Key" phx-debounce />
                </div>
                <div class="flex-1">
                  <.input field={input[:description]} placeholder="Description" phx-debounce />
                </div>
                <label class="flex cursor-pointer items-center align-text-bottom">
                  <input
                    type="checkbox"
                    name={"#{@panel.name}[input_drop][]"}
                    value={input.index}
                    class="hidden"
                  />
                  <div class="bg-alpha-4 size-6 mt-2 flex items-center justify-center rounded">
                    <.icon name="hero-x-mark-mini" class="h-5 w-5 align-bottom text-gray-900" />
                  </div>
                </label>
              </div>
            </.inputs_for>

            <label class="mt-2 flex h-8 w-fit cursor-pointer items-center whitespace-nowrap rounded p-2 text-sm font-bold text-blue-800 ring-1 ring-inset ring-blue-300 transition-colors disabled:pointer-events-none disabled:opacity-50">
              <input type="checkbox" name={"#{@panel.name}[input_sort][]"} class="hidden" />
              <div class="flex items-center gap-x-2">
                <.icon name="hero-plus-mini" class="size-5" /> Add input
              </div>
            </label>
          </div>

          <.input
            field={details_form[:__type__]}
            type="select"
            options={[
              {"Query", "query"}
            ]}
            value={get_polymorphic_type(@panel, :details)}
            label="Panel type"
          />
        </div>
        <.panel_details
          panel_form={@panel}
          details_form={details_form}
          source_module={source_module(details_form)}
          changeset={@changeset}
          credentials={@credentials}
        />
      </.polymorphic_embed_inputs_for>
    </div>
    """
  end

  defp panel_details(%{source_module: QueryPanel} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-4">
      <.select_with_search
        id={@details_form.id <> "-credential-search"}
        form={@details_form}
        label="Database user"
        selected={
          Enum.find_value(@credentials, &(&1.id == @details_form.data.credential_id && &1.name))
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
      <.input field={@details_form[:query]} type="textarea" label="Query to run" phx-debounce />
    </div>
    """
  end
end
