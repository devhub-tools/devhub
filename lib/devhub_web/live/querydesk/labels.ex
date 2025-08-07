defmodule DevhubWeb.Live.QueryDesk.Labels do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Shared
  alias Devhub.Shared.Schemas.Label

  def mount(_params, _session, socket) do
    color_options = [
      # pink
      "#f17eb8",
      "#bf125d",
      # red
      "#9b1c1c",
      "#771d1d",
      # orange
      "#fb923c",
      "#c2410c",
      # yellow
      "#fdf6b2",
      "#fce96a",
      # green
      "#0e9f6e",
      "#046c4e",
      "#014737",
      # blue
      "#61caff",
      "#1d6dbc",
      "#102951",
      # purple
      "#ac94fa",
      "#5521b5"
    ]

    labels =
      socket.assigns.organization.id
      |> Shared.list_labels()
      |> Enum.uniq_by(& &1.name)

    {:ok, assign(socket, page_title: "Devhub", labels: labels, changeset: nil, color_options: color_options)}
  end

  def render(assigns) do
    ~H"""
    <.page_header>
      <:header>
        <p class="text-alpha-64 text-2xl font-bold">
          Labels
        </p>
      </:header>
      <:actions>
        <.button phx-click="add_label">
          Add Label
        </.button>
      </:actions>
    </.page_header>

    <ul role="list" class="divide-alpha-8 bg-surface-1 divide-y rounded-lg">
      <li :for={label <- @labels} class="flex items-center justify-between p-4" data-testid="labels">
        <div class="flex items-center gap-x-2">
          <div class="mr-1 h-2 w-2 rounded-full" style={"background-color:#{label.color}"}></div>
          <p class="text-alpha-64 font-bold">{label.name}</p>
        </div>

        <div class="flex items-center gap-x-2">
          <button phx-click="edit_label" phx-value-id={label.id} data-testid="edit-icon">
            <.icon name="hero-pencil-square" class="size-5 text-gray-600 hover:text-gray-800" />
          </button>

          <button
            phx-click="delete_label"
            phx-value-id={label.id}
            data-confirm={"Are you sure you want to delete #{label.name}?"}
          >
            <.icon name="hero-trash" class="size-5 text-gray-600 hover:text-gray-800" />
          </button>
        </div>
      </li>
    </ul>

    <.edit_label_modal changeset={@changeset} color_options={@color_options} />
    """
  end

  def handle_event("add_label", _params, socket) do
    changeset = Label.changeset(%{})
    {:noreply, assign(socket, label: %Label{organization_id: socket.assigns.organization.id}, changeset: changeset)}
  end

  def handle_event("edit_label", %{"id" => id}, socket) do
    label = Enum.find(socket.assigns.labels, fn label -> label.id == id end)
    {:noreply, assign(socket, label: label, changeset: Label.changeset(label, %{"color" => label.color}))}
  end

  def handle_event("update_changeset", %{"label" => params}, socket) do
    changeset =
      socket.assigns.label
      |> Label.changeset(params)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("select_color", %{"color" => color}, socket) do
    changeset =
      socket.assigns.changeset
      |> Label.changeset(%{"color" => color})
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("delete_label", %{"id" => id}, socket) do
    label = Enum.find(socket.assigns.labels, fn label -> label.id == id end)

    case Shared.delete_label(label) do
      {:ok, label} ->
        labels = Enum.filter(socket.assigns.labels, fn l -> l.id != label.id end)
        {:noreply, assign(socket, labels: labels)}

      _error ->
        socket |> put_flash(:error, "Failed to delete label") |> noreply()
    end
  end

  def handle_event("save", %{"label" => params}, socket) do
    label = socket.assigns.label
    params = Map.take(params, ["name", "color"])

    case Shared.insert_or_update_label(label, params) do
      {:ok, label} ->
        labels = [label | socket.assigns.labels] |> Enum.uniq_by(& &1.name) |> Enum.sort_by(& &1.name)

        socket
        |> assign(labels: labels, label: nil, changeset: nil)
        |> noreply()

      {:error, changeset} ->
        socket |> put_flash(:error, "Failed to save label") |> assign(changeset: changeset) |> noreply()
    end
  end

  def handle_event("clear_changeset", _params, socket) do
    socket |> assign(changeset: nil) |> noreply()
  end

  defp edit_label_modal(assigns) do
    ~H"""
    <.modal :if={@changeset} id="label-modal" show={true} on_cancel={JS.push("clear_changeset")}>
      <.form
        :let={f}
        for={@changeset}
        phx-change="update_changeset"
        phx-submit="save"
        autocomplete="off"
        class="flex flex-col gap-y-4"
        data-testid="label-form"
      >
        <.input label="Name" field={f[:name]} />
        <.input type="color" field={f[:color]} label="Select a color" />
        <div class="flex flex-col gap-y-2">
          <p class="text-alpha-64 text-xs">OR CHOOSE FROM PRESETS</p>
          <div class="flex flex-wrap justify-between ">
            <button
              :for={color <- @color_options}
              type="button"
              phx-click="select_color"
              phx-value-color={color}
              class="size-3 rounded-full"
              style={"background-color: #{color}"}
              aria-label={"Select color #{color}"}
            >
            </button>
          </div>
        </div>

        <div class="mt-4 grid grid-cols-2 gap-4">
          <.button
            type="button"
            variant="secondary"
            phx-click="clear_changeset"
            aria-label={gettext("close")}
          >
            Cancel
          </.button>
          <.button type="submit" variant="primary" }>
            Save
          </.button>
        </div>
      </.form>
    </.modal>
    """
  end
end
