defmodule DevhubWeb.Live.Settings.LinearSettings do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations
  alias Devhub.Integrations.Linear
  alias Devhub.Integrations.Linear.Jobs.Import
  alias Devhub.Integrations.Linear.Label
  alias Devhub.Integrations.Linear.Team
  alias Devhub.Users

  def mount(_params, _session, socket) do
    {:ok, integration} = Integrations.get_by(organization_id: socket.assigns.organization.id, provider: :linear)

    team_options = socket.assigns.organization.id |> Users.list_teams() |> Enum.map(&{&1.name, &1.id})

    socket
    |> assign(
      page_title: "Devhub",
      integration: integration,
      form: to_form(Jason.decode!(integration.access_token)),
      labels: Linear.list_labels(socket.assigns.organization.id),
      teams: Linear.list_teams(socket.assigns.organization.id),
      team_options: team_options,
      import_status: "Starting import",
      import_percentage: 0,
      breadcrumbs: [
        %{title: "Integrations", path: ~p"/settings/integrations"},
        %{title: "Linear"}
      ]
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title="Linear settings">
        <:actions>
          <.dropdown
            id="github-actions"
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
                class="bg-alpha-4 ring-alpha-24 flex w-56 items-center justify-between rounded px-3 py-2 text-sm ring-1 transition-all ease-in-out"
              >
                <div><span class="text-alpha-40 mr-1">Actions:</span> Select...</div>
                <.icon name="hero-chevron-down" class="size-4" />
              </div>
            </:trigger>
            <div class="divide-alpha-8 bg-surface-2 mt-2 w-56 divide-y rounded px-3 py-1 py-4 text-xs ring-1 ring-gray-100 ring-opacity-5">
              <div class="flex flex-col items-start gap-y-3 px-1">
                <button
                  phx-click={show_modal("sync-modal") |> JS.push("sync")}
                  class="group flex items-center gap-x-2"
                  data-testid="sync-button"
                >
                  <.icon
                    name="hero-cloud-arrow-down"
                    class="size-4 text-gray-600 group-hover:text-gray-500"
                  />
                  <p class="text-gray-900 group-hover:text-gray-600">Sync</p>
                </button>
                <button phx-click={show_modal("update-modal")} class="group flex items-center gap-x-2">
                  <.icon
                    name="hero-cog-6-tooth"
                    class="size-4 text-gray-600 group-hover:text-gray-500"
                  />
                  <p class="text-gray-900 group-hover:text-gray-600">Update settings</p>
                </button>
              </div>
            </div>
          </.dropdown>
        </:actions>
      </.page_header>

      <div class="mt-4 grid grid-cols-2 gap-4">
        <div class="bg-surface-1 ring-alpha-8 rounded-lg">
          <dl class="divide-alpha-8 flex flex-col divide-y">
            <div class="flex-auto p-6">
              <dt class="text-alpha-64 font-semibold">Teams</dt>
            </div>
            <ul role="list" class="divide-alpha-4 divide-y">
              <li :for={team <- @teams} class="flex items-center justify-between px-6 py-4">
                <p class="truncate text-sm font-semibold">{team.name}</p>
                <.form
                  :let={f}
                  for={Team.changeset(team, %{})}
                  phx-change="update_team"
                  phx-value-id={team.id}
                >
                  <.input
                    field={f[:team_id]}
                    type="select"
                    prompt="Assign to team"
                    options={@team_options}
                  />
                </.form>
              </li>
            </ul>
          </dl>
        </div>
        <div class="bg-surface-1 ring-alpha-8 rounded-lg">
          <dl class="divide-alpha-8 flex flex-col divide-y">
            <div class="flex-auto p-6">
              <dt class="text-alpha-64 font-semibold">Labels</dt>
            </div>
            <ul role="list" class="divide-alpha-4 divide-y">
              <li
                :for={label <- @labels}
                :if={is_nil(label.parent_label_id)}
                class="flex flex-col items-center px-6 py-4"
              >
                <div class="flex w-full items-center justify-between">
                  <div class="flex items-center truncate text-sm font-semibold">
                    <div class="mr-2 h-2 w-2 rounded-full" style={"background-color: #{label.color}"}>
                    </div>
                    <div class="flex flex-col gap-y-1">
                      <p>{label.name}</p>
                      <p class="text-alpha-64 text-xs">
                        {(label.team && "Team label: #{label.team.name}") || "Workspace label"}
                      </p>
                    </div>
                  </div>
                  <.form
                    :let={f}
                    for={Label.form_changeset(label, %{})}
                    phx-change="update_label"
                    phx-value-id={label.id}
                    class="text-alpha-64 flex items-center gap-x-2 text-sm"
                  >
                    <span>Type:</span>
                    <.input
                      field={f[:type]}
                      type="select"
                      options={[{"Feature", "feature"}, {"Bug", "bug"}, {"Tech debt", "tech_debt"}]}
                    />
                  </.form>
                </div>
                <div :if={label.is_group} class="w-full">
                  <ul role="list" class="mt-4 flex flex-col gap-y-4">
                    <li
                      :for={child <- @labels}
                      :if={child.parent_label_id == label.id}
                      class="ml-6 flex items-center justify-between"
                    >
                      <div class="flex items-center">
                        <div
                          class="mr-2 h-2 w-2 rounded-full"
                          style={"background-color: #{child.color}"}
                        >
                        </div>
                        <div class="flex flex-col gap-y-1">
                          <p>{child.name}</p>
                        </div>
                      </div>
                      <.form
                        :let={f}
                        for={Label.form_changeset(child, %{})}
                        phx-change="update_label"
                        phx-value-id={child.id}
                        class="text-alpha-64 flex items-center gap-x-2 text-sm"
                      >
                        <span>Type:</span>
                        <.input
                          field={f[:type]}
                          type="select"
                          options={[
                            {"Feature", "feature"},
                            {"Bug", "bug"},
                            {"Tech debt", "tech_debt"}
                          ]}
                        />
                      </.form>
                    </li>
                  </ul>
                </div>
              </li>
            </ul>
          </dl>
        </div>
      </div>
    </div>

    <.modal id="sync-modal">
      <div class="relative">
        <div class="mb-6 text-center">
          <h3 class="text-base font-semibold text-gray-900">
            Syncing Linear data
          </h3>
          <div class="mt-2">
            <p class="text-sm text-gray-500">
              You can close this modal and the sync will continue in the background.
            </p>
          </div>
        </div>
      </div>

      <div :if={@import_percentage < 100}>
        <h4 class="sr-only">Status</h4>
        <div class="mt-4 flex items-center gap-x-1" data-testid="linear-import-status">
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

      <div :if={@import_percentage == 100}>
        <h4 class="sr-only">Status</h4>
        <div class="mt-4 flex items-center justify-between">
          <p class="text-alpha-64 text-sm font-medium">Your sync is complete</p>
          <.button
            type="button"
            variant="secondary"
            phx-click={JS.exec("data-cancel", to: "#sync-modal")}
            aria-label={gettext("close")}
          >
            Done
          </.button>
        </div>
      </div>
    </.modal>

    <.modal id="update-modal">
      <div class="mb-8 flex flex-col items-center gap-y-3">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="400"
          height="100"
          viewBox="0 0 400 100"
          fill="currentColor"
          class="h-10 w-fit"
        >
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M12.9266 16.3713c-.5283.5806-.4933 1.4714.0617 2.0265l68.5946 68.5946c.5551.555 1.4459.59 2.0265.0617 10.0579-9.1522 16.3713-22.3478 16.3713-37.0179C99.9807 22.402 77.5788 0 49.9445 0 35.2744 0 22.0788 6.31337 12.9266 16.3713ZM4.35334 29.3894c-.25348.5589-.12567 1.2142.30824 1.6481L68.9432 95.3191c.4339.4339 1.0892.5617 1.6481.3083 1.485-.6736 2.9312-1.4176 4.3344-2.2277.8341-.4815.9618-1.6195.2808-2.3005L8.88146 24.7742c-.68097-.681-1.81894-.5532-2.30045.2808-.81013 1.4032-1.55411 2.8494-2.22767 4.3344ZM.453579 47.796c-.300979-.301-.46112014-.7158-.4327856-1.1405.1327026-1.9891.3816396-3.9463.7400796-5.865.214926-1.1505 1.620727-1.5497 2.448307-.7222L59.9124 96.7715c.8275.8276.4283 2.2334-.7222 2.4483-1.9187.3585-3.8759.6074-5.865.7401-.4247.0283-.8395-.1318-1.1405-.4328L.453579 47.796ZM3.93331 61.7589c-1.0331-1.0331-2.70028-.1429-2.32193 1.2683C6.22104 80.2203 19.7604 93.7597 36.9535 98.3693c1.4112.3784 2.3014-1.2888 1.2683-2.3219L3.93331 61.7589ZM201.602 27.535c3.587 0 6.494-2.918 6.494-6.5175S205.189 14.5 201.602 14.5c-3.586 0-6.493 2.918-6.493 6.5175s2.907 6.5175 6.493 6.5175Zm-55.621 56.8396V14.5039h11.54v59.648h31.115v10.2227h-42.655Zm82.136-28.511v28.511h-11.166V34.8555h11.026v8.4876l.14-.0937c1.121-2.6573 2.928-4.8769 5.42-6.6589 2.491-1.8132 5.668-2.7198 9.531-2.7198 3.426 0 6.54.766 9.344 2.2978 2.803 1.5006 5.045 3.7045 6.727 6.6119 1.682 2.9074 2.523 6.4713 2.523 10.6916v30.9026h-11.166V55.0195c0-3.7514-.997-6.5963-2.99-8.5345-1.962-1.9695-4.594-2.9543-7.896-2.9543-2.118 0-4.049.4377-5.793 1.313-1.744.8754-3.13 2.2196-4.158 4.0328-1.028 1.8132-1.542 4.1422-1.542 6.9871Zm101.105 27.6669c2.554 1.0942 5.482 1.6413 8.783 1.6413 2.71 0 5.03-.3439 6.961-1.0317 1.932-.719 3.52-1.6725 4.766-2.8605 1.277-1.1879 2.289-2.4853 3.037-3.8921h.187v6.9871h10.699V50.2833c0-2.4072-.468-4.6111-1.402-6.6119-.934-2.0008-2.289-3.7358-4.065-5.2051-1.744-1.4694-3.862-2.5948-6.354-3.3763-2.491-.8129-5.295-1.2193-8.409-1.2193-4.267 0-7.958.7347-11.073 2.204-3.084 1.4381-5.497 3.3763-7.242 5.8148-1.744 2.4384-2.694 5.1895-2.85 8.2531h10.793c.124-1.438.623-2.7198 1.495-3.8452.872-1.1254 2.056-2.0008 3.551-2.626 1.495-.6565 3.223-.9848 5.186-.9848 1.962 0 3.628.3283 4.999.9848 1.401.6565 2.476 1.5475 3.223 2.6729.748 1.1254 1.122 2.4384 1.122 3.939v.3752c0 1.1254-.39 1.9538-1.168 2.4853-.748.5314-2.025.9222-3.831 1.1723-1.776.2501-4.205.5471-7.289.891-2.523.2813-4.952.7034-7.288 1.2661-2.336.5627-4.423 1.3912-6.261 2.4853-1.806 1.0942-3.239 2.5479-4.298 4.3611-1.059 1.8132-1.588 4.1422-1.588 6.987 0 3.2826.747 6.0336 2.242 8.2532 1.495 2.1884 3.52 3.8453 6.074 4.9707Zm18.081-8.3001c-1.807.9691-4.034 1.4537-6.681 1.4537-2.679 0-4.813-.5627-6.401-1.6881-1.589-1.1567-2.383-2.7355-2.383-4.7362 0-1.5631.436-2.8293 1.308-3.7984.904-.9691 2.087-1.735 3.551-2.2977 1.464-.5628 3.052-.9535 4.765-1.1724 1.246-.1875 2.461-.3751 3.645-.5627 1.183-.2188 2.289-.422 3.317-.6096 1.028-.2188 1.9-.4377 2.616-.6565.748-.2188 1.293-.4533 1.635-.7034v5.5334c0 1.9382-.451 3.7202-1.355 5.3458-.872 1.5944-2.211 2.8917-4.017 3.8921Zm26.094 9.1442V34.8555h10.745v8.1594h.141c.903-2.8136 2.32-4.955 4.251-6.4244 1.962-1.5005 4.532-2.2508 7.709-2.2508.779 0 1.48.0312 2.102.0938.655.0312 1.2.0625 1.636.0937v10.082c-.405-.0625-1.122-.1406-2.149-.2344-1.028-.0938-2.118-.1407-3.271-.1407-1.838 0-3.519.422-5.046 1.2661-1.526.8441-2.741 2.1415-3.644 3.8921-.872 1.7195-1.308 3.8922-1.308 6.5182v28.4641h-11.166Zm-177.401 0V34.8555h11.166v49.5191h-11.166Zm84.238-2.204c3.582 2.2196 7.834 3.3294 12.755 3.3294 3.8 0 7.257-.6878 10.372-2.0633 3.146-1.4068 5.762-3.3294 7.849-5.7678 2.087-2.4697 3.442-5.3146 4.065-8.5346h-10.512c-.468 1.4693-1.231 2.7667-2.29 3.8921-1.027 1.0942-2.32 1.9539-3.877 2.5792-1.558.6252-3.364.9378-5.42.9378-2.772 0-5.155-.6252-7.148-1.8757-1.962-1.2505-3.457-2.9855-4.485-5.2051-.933-2.043-1.443-4.3564-1.529-6.9402h35.915v-3.0012c0-3.8139-.561-7.284-1.682-10.4102-1.121-3.1575-2.71-5.8773-4.766-8.1594-2.055-2.3134-4.531-4.0953-7.428-5.3458-2.866-1.2505-6.058-1.8757-9.578-1.8757-4.578 0-8.627 1.1098-12.147 3.3294-3.52 2.2196-6.276 5.2833-8.27 9.191-1.993 3.9078-2.99 8.3782-2.99 13.4114 0 5.0019.966 9.4568 2.897 13.3645 1.931 3.8765 4.688 6.9246 8.269 9.1442Zm23.501-32.7783c-1.028-2.1258-2.492-3.767-4.392-4.9237-1.9-1.1567-4.142-1.7351-6.728-1.7351-2.554 0-4.781.5784-6.681 1.7351-1.868 1.1567-3.332 2.7979-4.391 4.9237-.756 1.5396-1.234 3.2903-1.434 5.2521h25.059c-.2-1.9618-.678-3.7125-1.433-5.2521Z"
          >
          </path>
        </svg>
      </div>
      <.form :let={f} for={@form} phx-submit="update_secrets" class="mt-6 flex flex-col gap-y-4">
        <.input field={f[:access_token]} label="Access token" />
        <span class="text-alpha-64 -mt-4 text-xs">
          Click on "Create & copy token" next to "Developer token" and choose "Application".
        </span>
        <.input field={f[:webhook_secret]} label="Webhook signing secret" />
        <span class="text-alpha-64 -mt-4 text-xs">
          The webhook signing secret can be found inside edit application and will begin with <span class="font-bold">lin_wh_</span>.
        </span>
        <div class="mt-4 grid grid-cols-2 gap-4">
          <.button
            type="button"
            variant="secondary"
            phx-click={JS.exec("data-cancel", to: "#update-modal")}
            aria-label={gettext("close")}
          >
            Cancel
          </.button>
          <.button type="submit" variant="primary">Save</.button>
        </div>
      </.form>
    </.modal>
    """
  end

  def handle_event("update_team", %{"id" => id, "team" => %{"team_id" => team_id}}, socket) do
    linear_team = Enum.find(socket.assigns.teams, &(&1.id == id))

    team_id =
      case Enum.find(socket.assigns.team_options, &(elem(&1, 1) == team_id)) do
        {_name, team_id} -> team_id
        _not_found -> nil
      end

    case Linear.update_linear_team(linear_team, %{"team_id" => team_id}) do
      {:ok, _team} ->
        socket |> put_flash(:info, "Team updated") |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to update team") |> noreply()
    end
  end

  def handle_event("update_label", %{"id" => id, "label" => %{"type" => type}}, socket) do
    label = Enum.find(socket.assigns.labels, &(&1.id == id))

    case Linear.update_label(label, %{type: type}) do
      {:ok, _label} ->
        socket |> put_flash(:info, "Label updated") |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to update label") |> noreply()
    end
  end

  def handle_event("sync", _params, socket) do
    Phoenix.PubSub.subscribe(Devhub.PubSub, "linear_sync:#{socket.assigns.organization.id}")

    # sync 30 days quickly to provide feedback to user
    %{id: socket.assigns.integration.id, days_to_sync: 30} |> Import.new() |> Oban.insert!()

    # sync 365 days with min priority
    %{id: socket.assigns.integration.id, days_to_sync: 365} |> Import.new(priority: 9) |> Oban.insert!()

    {:noreply, socket}
  end

  def handle_event("update_secrets", params, socket) do
    socket.assigns.integration
    |> Integrations.update(%{access_token: Jason.encode!(params)})
    |> case do
      {:ok, _integration} ->
        socket |> push_navigate(to: ~p"/settings/integrations/linear") |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to update settings.") |> noreply()
    end
  end

  def handle_info({:import_status, details}, socket) do
    socket |> assign(import_status: details.message, import_percentage: details.percentage) |> noreply()
  end
end
