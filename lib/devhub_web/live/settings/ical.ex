defmodule DevhubWeb.Live.Settings.Ical do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Calendar
  alias Devhub.Integrations
  alias Devhub.Integrations.Schemas.Ical

  @colors [
    "gray",
    "green",
    "orange",
    "yellow",
    "blue",
    "purple",
    "pink",
    "red"
  ]

  def mount(_params, _session, socket) do
    integrations = socket.assigns.organization |> Integrations.list(:ical) |> Enum.sort_by(& &1.title)
    create_changeset = Ical.changeset(%{})

    socket
    |> assign(
      page_title: "Devhub",
      colors: @colors,
      create_changeset: create_changeset,
      update_changeset: nil,
      integrations: integrations,
      breadcrumbs: [
        %{title: "Settings", path: ~p"/settings/integrations"},
        %{title: "iCal"}
      ]
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header>
        <:header>
          <div class="flex min-w-0 gap-x-4">
            <div class="min-w-0 flex-auto">
              <p class="text-2xl font-bold text-gray-900">
                Calendar Events (iCal)
              </p>
            </div>
          </div>
        </:header>
        <:actions>
          <.button phx-click={show_modal("new-ical")}>Add calendar</.button>
        </:actions>
      </.page_header>

      <.modal id="new-ical">
        <div>
          <div class="mb-6 text-center">
            <h3 class="text-base font-semibold text-gray-900">
              Setup iCal Integration
            </h3>
            <div class="mt-2">
              <p class="text-sm text-gray-500">
                Your iCal link will be synced hourly to update events on the calendar.
              </p>
            </div>
          </div>
        </div>
        <.form :let={f} for={@create_changeset} phx-submit="create_integration">
          <div class="flex flex-col gap-y-4">
            <.input id="create_ical_link" label="iCal Link" field={f[:link]} />
            <.input id="create_event_title" label="Event Title" field={f[:title]} />
            <.input
              id="create_event_color"
              label="Event Color"
              field={f[:color]}
              type="select"
              value="red"
              options={@colors}
            />
          </div>
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#new-ical")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit" variant="primary">Save</.button>
          </div>
        </.form>
      </.modal>

      <div class="bg-surface-1 rounded-lg p-4">
        <.table id="ical-integrations" rows={@integrations}>
          <:col :let={integration} label="Title" class="w-1/12">
            {integration.title}
          </:col>
          <:col :let={integration} label="Color" class="w-1/12">
            {integration.color}
          </:col>
          <:col :let={integration} label="Link">
            <div class="truncate">
              {integration.link}
            </div>
          </:col>
          <:action :let={integration}>
            <.dropdown id={"#{integration.id}-options"}>
              <:trigger>
                <div class="bg-alpha-4 rounded-md p-1">
                  <.icon name="hero-ellipsis-vertical" class="size-5 text-gray-900" />
                </div>
              </:trigger>
              <div class="divide-alpha-8 bg-surface-2 absolute top-2 -right-10 w-48 divide-y rounded px-2 py-1 ring-1 ring-gray-100 ring-opacity-5">
                <div
                  class="w-full cursor-pointer px-4 py-3"
                  phx-click="sync_calendar"
                  phx-value-id={integration.id}
                >
                  <p class="mb-1 text-sm">Sync</p>
                </div>
                <div
                  class="w-full cursor-pointer px-4 py-3"
                  phx-click="edit_integration"
                  phx-value-id={integration.id}
                >
                  <p class="mb-1 text-sm">Edit</p>
                </div>
                <div>
                  <button
                    data-confirm={"Are you sure you want to delete #{integration.title}?"}
                    phx-click="delete_integration"
                    phx-value-id={integration.id}
                    class="px-4 py-3 text-red-500"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </.dropdown>
          </:action>
        </.table>
      </div>
      <.modal :if={@update_changeset} show={true} id="update-ical" on_cancel={JS.push("cancel_edit")}>
        <div>
          <div class="mb-6 text-center">
            <h3 class="text-base font-semibold text-gray-900">
              Edit iCal Integration
            </h3>
            <div class="mt-2">
              <p class="text-sm text-gray-500">
                Your iCal link will be synced hourly to update events on the calendar.
              </p>
            </div>
          </div>
        </div>
        <.form :let={f} for={@update_changeset} phx-submit="update_integration">
          <div class="flex flex-col gap-y-4">
            <.input label="iCal Link" field={f[:link]} />
            <.input label="Event Title" field={f[:title]} />
            <.input label="Event Color" field={f[:color]} type="select" options={@colors} />
          </div>
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#update-ical")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button type="submit" variant="primary">Save</.button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  def handle_event("sync_calendar", %{"id" => id}, socket) do
    socket.assigns.integrations
    |> Enum.find(&(&1.id == id))
    |> Calendar.sync()

    socket |> put_flash(:info, "Syncing calendar...") |> noreply()
  end

  def handle_event("edit_integration", %{"id" => id}, socket) do
    integration = Enum.find(socket.assigns.integrations, &(&1.id == id))
    changeset = Ical.changeset(integration, %{})

    socket |> assign(update_changeset: changeset) |> noreply()
  end

  def handle_event("cancel_edit", _params, socket) do
    socket |> assign(update_changeset: nil) |> noreply()
  end

  def handle_event("create_integration", %{"ical" => params}, socket) do
    %{organization: organization} = socket.assigns
    params = Map.put(params, "organization_id", organization.id)

    case Integrations.create_ical(params) do
      {:ok, _integration} ->
        socket
        |> put_flash(:info, "iCal integration created successfully")
        |> push_navigate(to: ~p"/settings/integrations/ical")
        |> noreply()

      {:error, changeset} ->
        {:noreply, assign(socket, create_changeset: changeset)}
    end
  end

  def handle_event("update_integration", %{"ical" => params}, socket) do
    %{organization: organization} = socket.assigns

    integration = socket.assigns.update_changeset.data
    params = Map.put(params, "organization_id", organization.id)

    case Integrations.update_ical(integration, params) do
      {:ok, _integration} ->
        socket
        |> put_flash(:info, "iCal integration updated successfully")
        |> push_navigate(to: ~p"/settings/integrations/ical")
        |> noreply()

      {:error, changeset} ->
        {:noreply, assign(socket, update_changeset: changeset)}
    end
  end

  def handle_event("delete_integration", %{"id" => id}, socket) do
    integration = Enum.find(socket.assigns.integrations, &(&1.id == id))

    case Integrations.delete_ical(integration) do
      {:ok, _integration} ->
        socket
        |> put_flash(:info, "iCal integration delete successfully")
        |> push_navigate(to: ~p"/settings/integrations/ical")
        |> noreply()

      {:error, _changeset} ->
        socket
        |> put_flash(:error, "Failed to delete iCal integration")
        |> noreply()
    end
  end
end
