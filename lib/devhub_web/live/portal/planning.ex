defmodule DevhubWeb.Live.Portal.Planning do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Calendar.Event
  alias Devhub.Integrations.Linear
  alias Devhub.Permissions
  alias Devhub.Users

  @colors [
    "gray",
    "green",
    "orange",
    "yellow",
    "blue",
    "purple",
    "pink"
  ]

  def mount(_params, _session, socket) do
    organization_user = Devhub.Repo.preload(socket.assigns.organization_user, :teams)

    {:ok,
     assign(socket,
       page_title: "Devhub",
       organization_user: organization_user,
       colors: @colors,
       event_changeset: nil,
       events: [],
       filtered_projects: [],
       filtered_users: [],
       selected_project_name: nil,
       selected_team_id: nil,
       selected_team_name: nil,
       selected_user_name: nil,
       start_date: nil,
       show_create_modal: false,
       show_update_modal: false,
       timeline: nil,
       teams: [],
       users: [],
       weeks: []
     )}
  end

  def handle_params(params, _uri, socket) do
    organization = socket.assigns.organization

    if connected?(socket) do
      %{assigns: %{start_date: start_date, end_date: end_date}} =
        socket = process_date(socket, params)

      teams = [%{id: nil, name: "All"}] ++ Users.list_teams(organization.id)
      team = Enum.find(teams, fn team -> team.id == params["team_id"] end)

      events =
        organization
        |> Devhub.Calendar.get_events(start_date, end_date)
        |> Enum.sort_by(&(&1.title == "OOO"))

      user_events =
        Enum.group_by(events, fn
          %{linear_user: %{name: name, organization_user: %{legal_name: legal_name}}} ->
            legal_name || name

          %{linear_user: %{name: name}} ->
            name

          event ->
            event.person
        end)

      projects = Linear.projects(organization.id)

      today = Date.utc_today()

      users =
        organization.id
        |> Linear.users(params["team_id"])
        |> Enum.map(fn
          %{name: name, organization_user: %{legal_name: legal_name}} = user ->
            Map.put(user, :events, user_events[legal_name || name] || [])

          %{name: name} = user ->
            Map.put(user, :events, user_events[name] || [])
        end)
        |> Enum.sort_by(fn user ->
          user.events
          |> Enum.find(%{}, fn event ->
            Date.compare(event.start_date, today) != :gt &&
              Date.compare(event.end_date, today) != :lt
          end)
          |> Map.get(:title)
        end)

      {:noreply,
       assign(socket,
         events: events,
         filtered_projects: projects,
         filtered_users: users,
         projects: projects,
         selected_team_id: team.id,
         selected_team_name: team.name,
         teams: teams,
         timeline: params["timeline"],
         users: users
       )}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="absolute inset-4 left-64">
      <.page_header>
        <:header>
          <.live_component
            id="filter"
            module={DevhubWeb.Components.Filter}
            uri={@uri}
            teams={@teams}
            selected_team_id={@selected_team_id}
            selected_team_name={@selected_team_name}
          />
        </:header>
        <:actions>
          <span class="tooltip tooltip-left">
            <.button
              :if={Permissions.can?(:manage_events, @organization_user)}
              phx-click="show_create_event_modal"
            >
              <.icon name="hero-plus" class="size-4" />
            </.button>
            <span class="tooltiptext text-nowrap">Add priority</span>
          </span>
          <.button phx-click="back_to_today" variant="secondary">Today</.button>
          <.form :let={f} for={%{"timeline" => @timeline}} phx-change="update_timeline">
            <div class="-mt-2">
              <.input
                type="select"
                field={f[:timeline]}
                options={[{"Month", "month"}, {"Quarter", "quarter"}]}
              />
            </div>
          </.form>

          <span class="isolate inline-flex rounded-md">
            <button
              type="button"
              phx-click="previous_week"
              class="bg-alpha-8 ring-alpha-16 relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset hover:bg-alpha-16 focus:z-10"
              data-testid="prev"
            >
              <span class="sr-only">Previous</span>
              <.icon name="hero-chevron-left-mini" class="h-5 w-5" />
            </button>
            <button
              type="button"
              phx-click="next_week"
              class="bg-alpha-8 ring-alpha-16 relative -ml-px inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset hover:bg-alpha-16 focus:z-10"
              data-testid="next"
            >
              <span class="sr-only">Next</span>
              <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path
                  fill-rule="evenodd"
                  d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </span>
        </:actions>
      </.page_header>

      <div
        class="bg-surface-1 top-[5.5rem] absolute inset-0 flex flex-col rounded-lg"
        data-testid="calendar"
      >
        <div class="isolate flex flex-col overflow-auto">
          <div class="flex max-w-full flex-none flex-col md:max-w-full">
            <div class="bg-surface-1 border-alpha-16 sticky top-0 z-30 flex-none rounded-t-lg border-b pr-8">
              <div
                class="divide-alpha-8 border-alpha-8 text-alpha-64 -mr-px grid divide-x border-r text-sm"
                style={"grid-template-columns: repeat(#{length(@weeks)}, minmax(0, 1fr))"}
              >
                <div class="col-end-1 w-36"></div>
                <div
                  :for={week <- @weeks}
                  class="flex items-center justify-center py-2"
                  data-testid="columns"
                >
                  <span class="flex items-baseline">
                    {Calendar.strftime(week, "%b")}
                    <span class={[
                      "ml-1.5 flex h-7 w-7 items-center justify-center font-semibold",
                      Date.compare(week, Date.utc_today() |> Date.beginning_of_week()) == :eq &&
                        "rounded-full bg-blue-800 text-blue-200"
                    ]}>
                      {Calendar.strftime(week, "%d")}
                    </span>
                  </span>
                </div>
              </div>
            </div>
            <div class="border-alpha-8 flex flex-auto border-b">
              <div class="ring-alpha-8 sticky left-0 z-10 w-36 flex-none ring-1"></div>
              <div class="grid flex-auto grid-cols-1 grid-rows-1">
                <!-- Horizontal lines -->
                <div
                  class="divide-alpha-8 col-start-1 col-end-2 row-start-1 grid divide-y"
                  style={"grid-template-rows: repeat(#{length(@users)}, minmax(3.5rem, 1fr))"}
                >
                  <div class="row-end-1 h-7"></div>
                  <div :for={user <- @users}>
                    <div class="sticky left-0 z-20 mt-5 -ml-32 w-32 truncate pr-2 text-right text-xs">
                      {user.name}
                    </div>
                  </div>
                </div>
                <!-- Vertical lines -->
                <div
                  class="divide-alpha-8 col-start-1 col-end-2 row-start-1 grid grid-rows-1 divide-x"
                  style={"grid-template-columns: repeat(#{length(@weeks)}, minmax(0, 1fr))"}
                >
                  <div
                    :for={{_week, index} <- Enum.with_index(@weeks)}
                    class={"col-start-#{index + 1} row-span-full"}
                  >
                  </div>
                  <div class={"col-start-#{length(@weeks) + 1} row-span-full w-8"}></div>
                </div>
                <!-- Events -->
                <ol
                  class="col-start-1 col-end-2 row-start-1 grid pr-8"
                  style={"grid-template-columns: repeat(#{length(@weeks) * 7}, minmax(0, 1fr)); grid-template-rows: 1.75rem repeat(#{length(@users)}, minmax(0, 1fr)) auto"}
                  data-testid="user_events"
                >
                  <%= for {user, index} <- Enum.with_index(@users) do %>
                    <%= for event <- user.events do %>
                      <li
                        :if={
                          Date.compare(event.start_date, @end_date) != :gt &&
                            Date.compare(event.end_date, @start_date) != :lt
                        }
                        class="relative mt-px flex"
                        style={"grid-row: #{index + 2} / span 1; grid-column: #{event_grid_column(event, @start_date)}"}
                      >
                        <button
                          phx-click="show_update_event_modal"
                          phx-value-event_id={event.id}
                          class={"bg-#{event.color}-100 group min-w-12 absolute inset-1 z-20 flex flex-col overflow-hidden rounded-lg p-1 px-2 text-sm hover:bg-#{event.color}-200 hover:z-50 hover:min-w-fit"}
                        >
                          <div class="order-1 flex flex-col truncate text-left" title={event.title}>
                            <div class={"text-#{event.color}-900 font-semibold"}>
                              {event.title}
                            </div>
                            <div class={"text-#{event.color}-700 text-xs"}>
                              {Devhub.Calendar.count_business_days(
                                event.start_date,
                                event.end_date
                              )} days
                            </div>
                          </div>
                        </button>
                      </li>
                    <% end %>
                  <% end %>
                </ol>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <.modal :if={@show_create_modal} id="add-priority" show={true} on_cancel={JS.push("cancel")}>
      <div class="flex flex-col gap-y-4">
        <div>
          <.label>Dev</.label>
          <.dropdown_with_search
            friendly_action_name="Developer search"
            filtered_objects={@filtered_users}
            selected_object_name={@selected_user_name}
            select_action="select_user"
            filter_action="filter_users"
          />
        </div>
        <div>
          <.label>Project</.label>
          <.dropdown_with_search
            friendly_action_name="Project search"
            filtered_objects={@filtered_projects}
            selected_object_name={@selected_project_name}
            select_action="select_project"
            filter_action="filter_projects"
          />
        </div>

        <.form
          :let={f}
          id="add-priority-form"
          for={@event_changeset}
          phx-submit="add_priority"
          class="flex flex-col gap-y-4"
        >
          <.input type="select" label="Color" field={f[:color]} value="blue" options={@colors} />
          <.input type="date" label="Start Date" field={f[:start_date]} />
          <.input type="date" label="End Date" field={f[:end_date]} />
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#add-priority")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit" variant="primary">Add</.button>
          </div>
        </.form>
      </div>
    </.modal>

    <.modal :if={@show_update_modal} on_cancel={JS.push("cancel")} id="update-priority" show={true}>
      <div class="flex flex-col gap-y-4">
        <div>
          <.label>Dev</.label>
          <.dropdown_with_search
            friendly_action_name="Developer search"
            filtered_objects={@filtered_users}
            selected_object_name={@selected_user_name}
            select_action="select_user"
            filter_action="filter_users"
          />
        </div>
        <div>
          <.label>Project</.label>
          <.dropdown_with_search
            friendly_action_name="Project search"
            filtered_objects={@filtered_projects}
            filter_action="filter_projects"
            selected_object_name={@selected_project_name}
            select_action="select_project"
          />
        </div>

        <.form
          :let={f}
          id="update-priority-form"
          for={@event_changeset}
          phx-submit="update_priority"
          class="flex flex-col gap-y-4"
        >
          <.input type="select" label="Color" field={f[:color]} options={@colors} />
          <.input type="date" label="Start Date" field={f[:start_date]} />
          <.input type="date" label="End Date" field={f[:end_date]} />
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button type="button" phx-click="delete_priority" variant="destructive">
              Delete
            </.button>
            <.button type="submit" variant="primary">Update</.button>
          </div>
        </.form>
      </div>
    </.modal>
    """
  end

  def handle_event("previous_week", _params, socket) do
    params =
      (socket.assigns.uri.query || "")
      |> URI.decode_query()
      |> Map.put(
        "date",
        socket.assigns.anchor_date
        |> Timex.shift(weeks: -1)
        |> to_string()
      )

    {:noreply, push_patch(socket, to: ~p"/portal/planning?#{params}")}
  end

  def handle_event("next_week", _params, socket) do
    params =
      (socket.assigns.uri.query || "")
      |> URI.decode_query()
      |> Map.put(
        "date",
        socket.assigns.anchor_date
        |> Timex.shift(weeks: 1)
        |> to_string()
      )

    {:noreply, push_patch(socket, to: ~p"/portal/planning?#{params}")}
  end

  def handle_event("back_to_today", _params, socket) do
    params =
      (socket.assigns.uri.query || "")
      |> URI.decode_query()
      |> Map.put(
        "date",
        to_string(Date.utc_today())
      )

    {:noreply, push_patch(socket, to: ~p"/portal/planning?#{params}")}
  end

  def handle_event("update_timeline", %{"timeline" => timeline}, socket) do
    params =
      (socket.assigns.uri.query || "")
      |> URI.decode_query()
      |> Map.put("timeline", timeline)

    {:noreply, push_patch(socket, to: ~p"/portal/planning?#{params}")}
  end

  def handle_event("add_priority", %{"event" => params}, socket) do
    params =
      socket.assigns.event_changeset.changes
      |> Map.put(:organization_id, socket.assigns.organization.id)
      |> Map.put(:start_date, params["start_date"])
      |> Map.put(:end_date, params["end_date"])
      |> Map.put(:color, params["color"])

    case Devhub.Calendar.create_event(params) do
      {:ok, _event} ->
        params = URI.decode_query(socket.assigns.uri.query || "")

        socket
        |> push_patch(to: ~p"/portal/planning?#{params}")
        |> assign(event_changeset: nil, selected_user_name: nil, selected_project_name: nil, show_create_modal: false)
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(event_changeset: changeset)
        |> noreply()
    end
  end

  def handle_event("update_priority", %{"event" => params}, socket) do
    params =
      socket.assigns.event_changeset.changes
      |> Map.put(:start_date, params["start_date"])
      |> Map.put(:end_date, params["end_date"])
      |> Map.put(:color, params["color"])

    {:ok, _event} =
      socket.assigns.update_event |> Event.changeset(params) |> Devhub.Repo.update()

    params = URI.decode_query(socket.assigns.uri.query || "")

    {:noreply,
     socket
     |> assign(
       selected_user_name: nil,
       selected_project_name: nil,
       update_event: nil,
       event_changeset: nil,
       show_update_modal: false
     )
     |> push_patch(to: ~p"/portal/planning?#{params}")}
  end

  def handle_event("delete_priority", _params, socket) do
    {:ok, _event} = Devhub.Repo.delete(socket.assigns.update_event)

    params = URI.decode_query(socket.assigns.uri.query || "")

    socket
    |> assign(
      selected_user_name: nil,
      selected_project_name: nil,
      update_event: nil,
      event_changeset: nil,
      selected_user_name: nil,
      selected_project_name: nil,
      show_update_modal: false
    )
    |> push_patch(to: ~p"/portal/planning?#{params}")
    |> noreply()
  end

  def handle_event("show_create_event_modal", _params, socket) do
    event_changeset =
      Event.changeset(%{
        organization_id: socket.assigns.organization.id,
        start_date: Date.add(Date.utc_today(), -1),
        end_date: Date.utc_today()
      })

    if Permissions.can?(:manage_events, socket.assigns.organization_user) do
      {:noreply, assign(socket, event_changeset: event_changeset, show_create_modal: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("show_update_event_modal", %{"event_id" => event_id}, socket) do
    event = Enum.find(socket.assigns.events, fn event -> event.id == event_id end)

    if not is_nil(event.linear_user) and Permissions.can?(:manage_events, socket.assigns.organization_user) do
      {:noreply,
       assign(socket,
         selected_user_name: event.linear_user.name,
         selected_project_name: event.title,
         update_event: event,
         event_changeset: Event.changeset(event, %{}),
         show_update_modal: true
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel", _params, socket) do
    {:noreply,
     assign(socket,
       selected_user_name: nil,
       selected_project_name: nil,
       update_event: nil,
       event_changeset: nil,
       show_create_modal: false,
       show_update_modal: false
     )}
  end

  def handle_event("clear_filter", _params, socket) do
    {:noreply,
     assign(socket,
       filtered_users: socket.assigns.users,
       filtered_projects: socket.assigns.projects
     )}
  end

  def handle_event("filter_users", %{"name" => filter}, socket) do
    filtered_users =
      Enum.filter(socket.assigns.users, fn user ->
        String.contains?(String.downcase(user.name || ""), String.downcase(filter))
      end)

    {:noreply, assign(socket, :filtered_users, filtered_users)}
  end

  def handle_event("select_user", %{"id" => linear_user_id}, socket) do
    changeset = socket.assigns.event_changeset

    user =
      Enum.find(socket.assigns.users, fn user -> user.id == linear_user_id end)

    changes = Map.put(changeset.changes, :linear_user_id, user.id)
    event_changeset = Event.changeset(changeset.data, changes)

    {:noreply,
     assign(socket,
       event_changeset: event_changeset,
       selected_user_name: user.name,
       filtered_users: socket.assigns.users
     )}
  end

  def handle_event("filter_projects", %{"name" => filter}, socket) do
    custom = [%{id: "custom:#{filter}", name: filter}]

    filtered_projects =
      Enum.filter(socket.assigns.projects, fn project ->
        String.contains?(String.downcase(project.name || ""), String.downcase(filter))
      end) ++ custom

    {:noreply, assign(socket, :filtered_projects, filtered_projects)}
  end

  def handle_event("select_project", %{"id" => "custom:" <> title}, socket) do
    changeset = socket.assigns.event_changeset
    changes = Map.put(changeset.changes, :title, title)

    event_changeset = Event.changeset(changeset.data, changes)

    {:noreply,
     assign(socket,
       event_changeset: event_changeset,
       selected_project_name: title,
       filtered_projects: socket.assigns.projects
     )}
  end

  def handle_event("select_project", %{"id" => project_id}, socket) do
    project =
      Enum.find(socket.assigns.projects, fn project -> project.id == project_id end)

    changes = Map.put(socket.assigns.event_changeset.changes, :title, project.name)

    event_changeset = Event.changeset(changes)

    {:noreply,
     assign(socket,
       event_changeset: event_changeset,
       selected_project_name: project.name,
       filtered_projects: socket.assigns.projects
     )}
  end

  defp event_grid_column(event, start_date) do
    days_since_start_date = Date.diff(event.start_date, start_date)
    event_duration = Date.diff(event.end_date, event.start_date)
    event_duration_since_start_date = Date.diff(event.end_date, start_date)

    "#{max(days_since_start_date + 1, 1)} / span #{min(event_duration, event_duration_since_start_date)}"
  end

  defp process_date(socket, params) do
    default_start =
      case params["timeline"] do
        "quarter" -> Timex.beginning_of_quarter(Date.utc_today())
        _default -> Date.utc_today()
      end

    anchor_date = (params["date"] && Date.from_iso8601!(params["date"])) || default_start

    start_date = Timex.beginning_of_week(anchor_date)

    end_date =
      case params["timeline"] do
        "quarter" -> anchor_date |> Timex.shift(weeks: 11) |> Timex.end_of_week()
        _default -> anchor_date |> Timex.shift(weeks: 4) |> Timex.end_of_week()
      end

    weeks =
      start_date
      |> Date.range(end_date)
      |> Enum.group_by(&Timex.beginning_of_week/1)
      |> Enum.map(fn {date, _dates} -> date end)
      |> Enum.sort(Date)

    assign(socket,
      anchor_date: anchor_date,
      start_date: start_date,
      end_date: end_date,
      weeks: weeks
    )
  end
end
