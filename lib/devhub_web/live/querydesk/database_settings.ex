defmodule DevhubWeb.Live.QueryDesk.DatabaseSettings do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Agents
  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.Utils
  alias DevhubPrivate.Live.QueryDesk.Components.DatabasePermissions
  alias Phoenix.LiveView.AsyncResult

  def mount(%{"id" => "new"}, _session, socket) do
    {:ok, database} = QueryDesk.create_database(%{organization_id: socket.assigns.organization.id})

    socket |> push_navigate(to: ~p"/querydesk/databases/#{database.id}") |> ok()
  end

  def mount(%{"id" => id}, _session, socket) do
    {:ok, database} =
      QueryDesk.get_database([id: id, organization_id: socket.assigns.organization.id],
        preload: [permissions: [:role, organization_user: :user]]
      )

    database = Utils.sort_permissions(database)

    agent_options =
      socket.assigns.organization.id
      |> Agents.list()
      |> Enum.map(&{&1.name, &1.id})

    socket
    |> assign(
      page_title: "#{database.name} | Devhub",
      agent_options: agent_options,
      database: database,
      connection_checks: %{},
      changeset: Database.changeset(database, %{}),
      breadcrumbs: [%{title: database.name || "New database"}]
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header
        title={@database.name || "New database"}
        subtitle={
          if not is_nil(@database.database),
            do: "Database: #{@database.database} (#{@database.adapter})"
        }
      >
        <:actions>
          <.dropdown
            :if={@organization_user.permissions.super_admin and not is_nil(@database.id)}
            id="workspace-actions"
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
                class="bg-alpha-4 ring-alpha-24 flex w-48 items-center justify-between rounded px-3 py-2 text-sm ring-1 transition-all ease-in-out"
              >
                <div><span class="text-alpha-40 mr-1">Actions:</span> Select...</div>
                <.icon name="hero-chevron-down" class="h-4 w-4" />
              </div>
            </:trigger>
            <div class="divide-alpha-8 bg-surface-2 mt-2 w-48 divide-y rounded px-3 py-1 py-4 text-xs ring-1 ring-gray-100 ring-opacity-5">
              <div class="flex flex-col items-start gap-y-3 px-1 pb-3">
                <.link
                  navigate={~p"/querydesk/databases/#{@database.id}/query"}
                  class="flex items-center gap-x-2"
                >
                  <.icon name="hero-command-line" class="h-4 w-4 text-gray-600 hover:text-gray-500" />
                  Connect
                </.link>
                <.link
                  navigate={~p"/querydesk/databases/audit-log?database_id=#{@database.id}"}
                  class="flex items-center gap-x-2"
                >
                  <.icon
                    name="hero-magnifying-glass"
                    class="h-4 w-4 text-gray-600 hover:text-gray-500"
                  /> View Audit Log
                </.link>

                <.link
                  :if={
                    @database.adapter == :postgres and
                      Code.ensure_loaded?(DevhubPrivate.DataProtection)
                  }
                  navigate={~p"/querydesk/databases/#{@database.id}/data-protection"}
                  class="flex items-center gap-x-2"
                >
                  <.icon name="hero-eye-slash" class="h-4 w-4 text-gray-600 hover:text-gray-500" />
                  Data protection
                </.link>
              </div>
              <div class="px-1 pt-3">
                <button
                  phx-click={show_modal("delete-modal")}
                  class="flex items-center gap-x-2 text-red-500"
                >
                  <.icon name="hero-trash" class="h-4 w-4" /> Delete Database
                </button>
              </div>
            </div>
          </.dropdown>
        </:actions>
      </.page_header>

      <.form :let={f} for={@changeset} phx-change="update" data-testid="database-form">
        <div class="flex flex-col gap-y-4">
          <div class="bg-surface-1 grid grid-cols-1 gap-x-4 gap-y-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Database Configuration</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                This information allows you to define the basic configuration of your database connection.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-4">
              <.input
                field={f[:name]}
                label="Display name"
                tooltip="Name for display purposes to identify this database. This is not used for the database connection."
                phx-debounce
              />
              <.input
                field={f[:hostname]}
                label="Database IP or hostname"
                tooltip="Do not include any extra info such as the scheme, only the IP or hostname, for example 10.1.0.132 or myinstance.123456789.us-east-1.rds.amazonaws.com."
                phx-debounce
              />
              <.input
                field={f[:port]}
                label="Port"
                tooltip="The port number to connect to the database on, if not specified the default port for the database type will be used."
                phx-debounce
              />
              <.input
                field={f[:database]}
                label="Database name"
                tooltip="The name of the database to connect to (or schema for MySQL)."
                phx-debounce
              />
              <.input
                type="select"
                field={f[:adapter]}
                label="Database type"
                options={[
                  {"PostgreSQL", "postgres"},
                  {"MySQL", "mysql"},
                  {"ClickHouse", "clickhouse"}
                ]}
              />
              <.input
                type="select"
                field={f[:agent_id]}
                label="Agent"
                prompt="None"
                options={@agent_options}
                tooltip="An agent is used to connect to databases inside of private networks, you can setup an agent in settings."
              />
              <.input
                field={f[:group]}
                label="Group (optional)"
                tooltip="Used to organize databases into folders in the database list."
                phx-debounce
              />
            </div>
          </div>

          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Credentials</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                Define credentials that your users are allowed to use for connecting to the database.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-4">
              <div>
                <div class="mb-1 grid grid-cols-10 items-center gap-x-4">
                  <div class="col-span-2">
                    <div class="text-alpha-64 text-xs uppercase">Username</div>
                  </div>
                  <div class="col-span-2">
                    <div class="text-alpha-64 text-xs uppercase">Password</div>
                  </div>
                  <div class="col-span-2">
                    <div class="text-alpha-64 text-xs uppercase">Hostname (optional)</div>
                  </div>
                  <div :if={Code.ensure_loaded?(DatabasePermissions)} class="col-span-2">
                    <div class="text-alpha-64 flex items-center gap-x-1 text-xs">
                      <span class="uppercase">Reviews</span>
                      <div class="tooltip tooltip-right">
                        <span class="bg-alpha-16 text-alpha-64 size-4 relative flex items-center justify-center rounded-full text-xs">
                          ?
                        </span>
                        <span class="tooltiptext w-64 p-2">
                          How many reviews should be required before a user can run a query. If 0, queries are run immediately. A general recommendation is to setup a readonly user that doesn't require reviews and a user with more access that requires reviews.
                        </span>
                      </div>
                    </div>
                  </div>
                  <div class="col-span-1">
                    <div class="text-alpha-64 flex items-center gap-x-1 text-xs">
                      <span class="uppercase">Default</span>
                      <div class="tooltip tooltip-right">
                        <span class="bg-alpha-16 text-alpha-64 size-4 relative flex items-center justify-center rounded-full text-xs">
                          ?
                        </span>
                        <span class="tooltiptext w-64 p-2">
                          The default credential is used for table views and for users connecting to the database proxy (if reviews required is set to 0).
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <.inputs_for :let={credential} field={f[:credentials]}>
                  <input type="hidden" name="database[credential_sort][]" value={credential.index} />
                  <div class="mb-1 grid grid-cols-10 items-start gap-x-4">
                    <div class="col-span-2">
                      <.input field={credential[:username]} autocomplete="off" phx-debounce />
                    </div>

                    <div class="col-span-2">
                      <.input
                        type="password"
                        field={credential[:password]}
                        value={credential.source.changes[:password]}
                        autocomplete="off"
                        phx-debounce
                      />
                    </div>

                    <div class="col-span-2">
                      <.input
                        field={credential[:hostname]}
                        autocomplete="off"
                        phx-debounce
                        placeholder={@database.hostname}
                      />
                    </div>

                    <div :if={Code.ensure_loaded?(DatabasePermissions)} class="col-span-2">
                      <.input field={credential[:reviews_required]} autocomplete="off" phx-debounce />
                    </div>

                    <div class="col-span-1 mt-3 flex items-center justify-center pt-2">
                      <.input field={credential[:default_credential]} type="checkbox" />
                    </div>
                    <div class="col-span-1 mt-2 flex items-center justify-center align-text-bottom">
                      <label
                        id={"#{credential.index}-delete-checkbox-label"}
                        phx-hook="SpaceToggle"
                        tabindex="0"
                      >
                        <input
                          type="checkbox"
                          name="database[credential_drop][]"
                          value={credential.index}
                          class="hidden"
                        />
                        <div class="bg-alpha-4 size-6 mt-2 flex items-center justify-center rounded-md">
                          <.icon name="hero-x-mark-mini" class="size-5 align-bottom text-gray-900" />
                        </div>
                      </label>
                    </div>
                  </div>
                  <div class="mb-2 flex items-center gap-x-2">
                    <.button
                      type="button"
                      phx-click="test_connection"
                      phx-value-id={credential[:id].value}
                      variant="text"
                    >
                      Test Connection
                    </.button>
                    <.async_result
                      :let={check}
                      :if={Map.has_key?(@connection_checks, credential[:id].value)}
                      assign={@connection_checks[credential[:id].value]}
                    >
                      <:loading>
                        <div class="size-4 ml-1">
                          <.spinner />
                        </div>
                      </:loading>

                      <div :if={check[:success]}>
                        <div class="text-sm text-green-500">
                          <.icon name="hero-check-circle" class="size-5" /> Connection successful
                        </div>
                      </div>
                      <div :if={check[:success] == false}>
                        <div class="text-sm text-red-500">
                          <.icon name="hero-exclamation-circle" class="size-5" /> {check[:error]}
                        </div>
                      </div>
                    </.async_result>
                  </div>
                </.inputs_for>
              </div>

              <label
                id="add-credential"
                tabindex="0"
                phx-hook="SpaceToggle"
                class="flex h-8 w-fit items-center whitespace-nowrap rounded-md p-2 text-sm font-bold text-blue-800 ring-1 ring-inset ring-blue-300 transition-colors disabled:pointer-events-none disabled:opacity-50"
              >
                <input type="checkbox" name="database[credential_sort][]" class="hidden" />
                <div class="flex items-center gap-x-2">
                  <.icon name="hero-plus-mini" class="size-5" /> Add Credential
                </div>
              </label>
            </div>
          </div>

          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">
                Encryption
              </h2>
              <p class="text-alpha-64 mt-1 text-sm">
                Define encryption settings for the connection to the database.
              </p>
            </div>

            <div class="col-span-5">
              <.input type="toggle" field={f[:ssl]} label="Enabled" />

              <div :if={f[:ssl].value in [true, "true"]} class="mt-6 flex flex-col gap-y-4">
                <.input
                  type="textarea"
                  field={f[:cacertfile]}
                  value={f.source.changes[:cacertfile]}
                  label="Server CA Certificate"
                  autocomplete="off"
                  phx-debounce
                />
                <.input
                  type="textarea"
                  field={f[:keyfile]}
                  value={f.source.changes[:keyfile]}
                  label="Client Key"
                  autocomplete="off"
                  phx-debounce
                />
                <.input
                  type="textarea"
                  field={f[:certfile]}
                  value={f.source.changes[:certfile]}
                  label="Client certificate"
                  autocomplete="off"
                  phx-debounce
                />
              </div>
            </div>
          </div>

          <div class="bg-surface-1 grid grid-cols-1 gap-4 rounded-lg p-4 md:grid-cols-7">
            <div class="col-span-2">
              <h2 class="text-base font-semibold text-gray-900">Slack Configuration</h2>
              <p class="text-alpha-64 mt-1 text-sm">
                If configured, messages will be posted to the requested channel when queries are submitted for review.
              </p>
            </div>

            <div class="col-span-5 flex flex-col gap-y-4">
              <.input field={f[:slack_channel]} label="slack channel" phx-debounce />
            </div>
          </div>

          <.live_component
            :if={Code.ensure_loaded?(DatabasePermissions)}
            module={DatabasePermissions}
            id="database-permissions"
            database_id={@database.id}
            form={f}
          />
        </div>
      </.form>
    </div>

    <.modal id="delete-modal">
      <div>
        <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-200">
          <.icon name="hero-exclamation-triangle" class="size-6 text-red-800" />
        </div>
        <div class="mt-3 text-center sm:mt-5">
          <h3 class="text-base font-semibold text-gray-900">
            Are you sure you want to delete this database?
          </h3>
        </div>
      </div>
      <div class="mt-4 grid grid-cols-2 gap-4">
        <.button
          type="button"
          variant="secondary"
          phx-click={JS.exec("data-cancel", to: "#delete-modal")}
          aria-label={gettext("close")}
        >
          Cancel
        </.button>
        <.button phx-click="delete" data-testid="delete-database" variant="destructive">
          Delete
        </.button>
      </div>
    </.modal>
    """
  end

  def handle_event("test_connection", %{"id" => credential_id}, socket) do
    database = socket.assigns.database

    socket
    |> assign(connection_checks: %{credential_id => AsyncResult.loading()})
    |> start_async(
      :connection_check,
      fn ->
        case QueryDesk.test_connection(database, credential_id) do
          :ok -> %{credential_id => AsyncResult.ok(%{success: true})}
          {:error, message} -> %{credential_id => AsyncResult.ok(%{success: false, error: message})}
        end
      end
    )
    |> noreply()
  end

  def handle_event("update", %{"database" => params, "_target" => target}, socket) do
    # clear out password if empty so we don't override the value if it wasn't updated

    params =
      if Map.has_key?(params, "credentials") do
        %{
          params
          | "credentials" =>
              Map.new(params["credentials"], fn {k, credential} ->
                if credential["password"] == "" do
                  {k, Map.delete(credential, "password")}
                else
                  {k, credential}
                end
              end)
        }
      else
        params
      end

    params =
      params
      |> Utils.delete_if_empty("cacertfile")
      |> Utils.delete_if_empty("keyfile")
      |> Utils.delete_if_empty("certfile")

    params =
      case target do
        # turn off default credential for all credentials except the one that was clicked
        ["database", "credentials", index, "default_credential"] ->
          Map.update!(params, "credentials", fn credentials ->
            Map.new(credentials, fn {key, credential} ->
              {key, Map.put(credential, "default_credential", key == index)}
            end)
          end)

        _target ->
          params
      end

    case QueryDesk.update_database(socket.assigns.database, params) do
      {:ok, database} ->
        database = Utils.sort_permissions(database)
        changeset = Database.changeset(database, %{})

        socket
        |> assign(database: database, changeset: changeset, connection_checks: %{})
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(changeset: changeset)
        |> noreply()
    end
  end

  def handle_event("delete", _params, socket) do
    case QueryDesk.delete_database(socket.assigns.database) do
      {:ok, _database} ->
        socket
        |> push_navigate(to: ~p"/querydesk")
        |> noreply()

      {:error, _changeset} ->
        socket
        |> put_flash(:error, "Failed to delete database.")
        |> noreply()
    end
  end

  def handle_async(:connection_check, {:ok, result}, socket) do
    socket
    |> assign(connection_checks: result)
    |> noreply()
  end
end
