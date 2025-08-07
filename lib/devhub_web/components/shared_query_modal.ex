defmodule DevhubWeb.Components.SharedQueryModal do
  @moduledoc false
  use DevhubWeb, :live_component

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SharedQuery

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign_new(:changeset, fn ->
      SharedQuery.changeset(%SharedQuery{}, %{
        "restricted_access" => false,
        "query" => assigns.query,
        "include_results" => is_map(assigns.results),
        "expires_at" => DateTime.add(DateTime.utc_now(), 24, :hour)
      })
    end)
    |> assign(
      shared_query: nil,
      modal_mode: "default"
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.modal
        :if={@changeset}
        id="share-query-modal"
        show={true}
        on_cancel={JS.push("cancel_shared_query", target: @myself)}
      >
        <.shared_query_link
          :if={@modal_mode == "link"}
          database={@database}
          shared_query={@shared_query}
        />

        <div>
          <.form
            :let={f}
            :if={@modal_mode == "default"}
            id="shared-query-form"
            for={@changeset}
            phx-submit="create_shared_query"
            phx-change="update_form"
            phx-target={@myself}
            class="focus-on-show flex flex-col gap-y-4"
          >
            <code class="bg-surface-3 max-h-48 overflow-auto break-all rounded p-4">
              <pre
                id={Ecto.UUID.generate()}
                phx-hook="SqlHighlight"
                data-query={f[:query].value}
                data-adapter={@database.adapter}
              />
            </code>
            <.input field={f[:query]} type="hidden" />

            <.input
              field={f[:expires]}
              type="toggle"
              label="Expires"
              tooltip="If enabled, the shared query will expire after the set time."
            />
            <div class={if f[:expires].value in [true, "true"], do: "block", else: "hidden"}>
              <.input
                field={f[:expires_at]}
                value={
                  f[:expires_at].value && Timex.Timezone.convert(f[:expires_at].value, @user.timezone)
                }
                type="datetime-local"
                label="Expires at"
              />
            </div>
            <.input field={f[:include_results]} type="toggle" label="Include results" />

            <div class="mt-6 sm:grid sm:grid-flow-row-dense sm:grid-cols-2 sm:gap-4">
              <.button
                type="button"
                variant="secondary"
                phx-click="cancel_shared_query"
                phx-target={@myself}
                aria-label={gettext("close")}
              >
                Cancel
              </.button>
              <.button type="submit" variant="primary">Share</.button>
            </div>
          </.form>
        </div>
      </.modal>
    </div>
    """
  end

  defp shared_query_link(assigns) do
    ~H"""
    <div id="share-query-link">
      <copy-text value={"#{DevhubWeb.Endpoint.url()}/querydesk/databases/#{@database.id}/query?shared_query_id=#{@shared_query.id}"} />
    </div>
    """
  end

  def handle_event("clear_filter", _params, socket) do
    {:noreply,
     assign(socket,
       filtered_users: nil,
       filtered_user_name: nil,
       filtered_roles: nil,
       filtered_role_name: nil,
       modal_mode: "default"
     )}
  end

  def handle_event("filter_users", %{"name" => filter}, socket) do
    filter = String.downcase(filter)

    filtered_users =
      Enum.filter(socket.assigns.users, fn user ->
        String.contains?(String.downcase(user.name || ""), filter) or
          String.contains?(String.downcase(user.email || ""), filter)
      end)

    {:noreply, assign(socket, :filtered_users, filtered_users)}
  end

  def handle_event("select_user", %{"id" => id}, socket) do
    user = Enum.find(socket.assigns.users, fn user -> user.id == id end)

    {:noreply, assign(socket, selected_user: user, selected_user_name: user.name)}
  end

  def handle_event("filter_roles", %{"name" => filter}, socket) do
    filter = String.downcase(filter)

    filtered_roles =
      Enum.filter(socket.assigns.roles, fn role ->
        String.contains?(String.downcase(role.name || ""), filter)
      end)

    {:noreply, assign(socket, :filtered_roles, filtered_roles)}
  end

  def handle_event("select_role", %{"id" => id}, socket) do
    role = Enum.find(socket.assigns.roles, fn role -> role.id == id end)

    {:noreply, assign(socket, selected_role: role, selected_role_name: role.name)}
  end

  def handle_event("add_role_viewer", _params, socket) do
    params = socket.assigns.changeset.changes
    permissions = Ecto.Changeset.get_field(socket.assigns.changeset, :permissions)
    role = socket.assigns.selected_role

    permissions = [
      %{
        "permission" => "read",
        "role_id" => role.id
      }
      | Enum.map(permissions, fn permission ->
          %{
            "permission" => "read",
            "role_id" => permission.role_id,
            "organization_user_id" => permission.organization_user_id
          }
        end)
    ]

    params = Map.put(params, :permissions, permissions)
    changeset = SharedQuery.changeset(params)

    socket
    |> assign(changeset: changeset, selected_role_name: nil, modal_mode: "default")
    |> noreply()
  end

  def handle_event("add_user_viewer", _params, socket) do
    params = socket.assigns.changeset.changes
    permissions = Ecto.Changeset.get_field(socket.assigns.changeset, :permissions)
    organization_user = hd(socket.assigns.selected_user.organization_users)

    permissions = [
      %{
        "permission" => "read",
        "organization_user_id" => organization_user.id
      }
      | Enum.map(permissions, fn permission ->
          %{
            "permission" => "read",
            "role_id" => permission.role_id,
            "organization_user_id" => permission.organization_user_id
          }
        end)
    ]

    params = Map.put(params, :permissions, permissions)

    changeset = SharedQuery.changeset(params)

    socket
    |> assign(changeset: changeset, selected_user_name: nil, modal_mode: "default")
    |> noreply()
  end

  def handle_event("update_form", %{"shared_query" => params}, socket) do
    params =
      Map.put(
        params,
        "expires_at",
        (params["expires_at"] <> ":00")
        |> NaiveDateTime.from_iso8601!()
        |> DateTime.from_naive!(socket.assigns.user.timezone)
      )

    changeset = SharedQuery.changeset(params)

    socket
    |> assign(changeset: changeset)
    |> noreply()
  end

  def handle_event("create_shared_query", %{"shared_query" => params}, socket) do
    params =
      params
      |> Map.put("database_id", socket.assigns.database.id)
      |> Map.put("created_by_user_id", socket.assigns.organization_user.user_id)
      |> Map.put("organization_id", socket.assigns.organization.id)

    results = socket.assigns.results

    params =
      if params["include_results"] == "true" do
        {:ok, results} = results |> Jason.encode!() |> :brotli.encode(%{quality: 5})

        Map.put(params, "results", results)
      else
        params
      end

    params =
      if params["expires"] == "false" do
        Map.delete(params, "expires_at")
      else
        params
      end

    case QueryDesk.save_shared_query(params) do
      {:ok, shared_query} ->
        socket
        |> assign(
          modal_mode: "link",
          shared_query: shared_query
        )
        |> noreply()

      {:error, changeset} ->
        socket |> assign(changeset: changeset) |> noreply()
    end
  end

  def handle_event("set_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, modal_mode: mode)}
  end

  def handle_event("cancel_shared_query", _params, socket) do
    send(self(), :close_shared_query_modal)
    {:noreply, assign(socket, changeset: nil)}
  end
end
