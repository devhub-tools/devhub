defmodule DevhubWeb.Live.Settings.Integrations do
  @moduledoc false
  use DevhubWeb, :live_view

  import DevhubWeb.Components.SettingsTabs

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Schemas.Integration

  @slack_manifest %{
                    display_information: %{
                      name: "Devhub",
                      description: "Devhub Slack integration",
                      background_color: "#12346a"
                    },
                    features: %{
                      app_home: %{
                        home_tab_enabled: false,
                        messages_tab_enabled: true,
                        messages_tab_read_only_enabled: true
                      },
                      bot_user: %{
                        display_name: "Devhub",
                        always_online: true
                      }
                    },
                    oauth_config: %{
                      scopes: %{
                        bot: [
                          "chat:write",
                          "reactions:write"
                        ]
                      }
                    },
                    settings: %{
                      org_deploy_enabled: false,
                      socket_mode_enabled: false,
                      token_rotation_enabled: false
                    }
                  }
                  |> Jason.encode!()
                  |> Jason.Formatter.pretty_print()

  def mount(_params, _session, socket) do
    integrations = Integrations.list(socket.assigns.organization)
    github_setup_complete = GitHub.setup_complete?(socket.assigns.organization)

    linear = Enum.find(integrations, &(&1.provider == :linear))
    github = Enum.find(integrations, &(&1.provider == :github))
    ai = Enum.find(integrations, %Integration{provider: :ai}, &(&1.provider == :ai))

    slack =
      integrations
      |> Enum.find(%Integration{provider: :slack, access_token: "{}"}, &(&1.provider == :slack))
      |> then(fn slack ->
        # %{"app_level_token" => app_level_token, "bot_token" => bot_token} = Jason.decode!(slack.access_token)
        # slack |> Map.put(:app_level_token, app_level_token) |> Map.put(:bot_token, bot_token)
        case Jason.decode(slack.access_token) do
          %{"bot_token" => bot_token} -> Map.put(slack, :bot_token, bot_token)
          _empty -> slack
        end
      end)

    socket
    |> assign(
      page_title: "Devhub",
      integrations: integrations,
      github_setup_complete: github_setup_complete,
      linear: linear,
      github: github,
      ai: ai,
      slack: slack,
      slack_manifest: @slack_manifest,
      show_slack_instructions: false
    )
    |> ok()
  end

  def render(assigns) do
    ai_changeset = Integration.changeset(assigns.ai, %{})
    slack_changeset = Integration.changeset(assigns.slack, %{})

    assigns =
      assign(assigns,
        ai_changeset: ai_changeset,
        slack_changeset: slack_changeset
      )

    ~H"""
    <div class="text-sm">
      <.page_header>
        <:header>
          <.settings_tabs active_path={@active_path} organization_user={@organization_user} />
        </:header>
      </.page_header>
      <div class="mt-4 grid grid-cols-2 gap-4">
        <div class="bg-surface-1 ring-alpha-8 flex items-center justify-between rounded-lg p-4">
          <h2 class="text-xl font-bold">GitHub</h2>
          <.link_button
            :if={not @github_setup_complete}
            variant="outline"
            navigate={~p"/settings/integrations/github/setup"}
          >
            Setup
          </.link_button>

          <.link_button
            :if={@github_setup_complete}
            variant="outline"
            navigate={~p"/settings/integrations/github"}
          >
            Settings
          </.link_button>
        </div>
        <div class="bg-surface-1 ring-alpha-8 flex items-center justify-between rounded-lg p-4">
          <h2 class="text-xl font-bold">Linear</h2>
          <div class="flex items-center">
            <.link_button
              :if={is_nil(@linear)}
              variant="outline"
              navigate={~p"/settings/integrations/linear/setup"}
            >
              Setup
            </.link_button>
            <.link_button
              :if={not is_nil(@linear)}
              variant="outline"
              navigate={~p"/settings/integrations/linear"}
            >
              Settings
            </.link_button>
          </div>
        </div>
        <div class="bg-surface-1 ring-alpha-8 flex items-center justify-between rounded-lg p-4">
          <h2 class="text-xl font-bold">Slack</h2>
          <.button variant="outline" phx-click={show_modal("slack-settings")}>
            Settings
          </.button>
        </div>
        <div class="bg-surface-1 ring-alpha-8 flex items-center justify-between rounded-lg p-4">
          <h2 class="text-xl font-bold">AI</h2>
          <.button variant="outline" phx-click={show_modal("ai-settings")}>
            Settings
          </.button>
        </div>
        <div class="bg-surface-1 ring-alpha-8 flex items-center justify-between rounded-lg p-4">
          <h2 class="text-xl font-bold">Calendar Events (iCal)</h2>
          <.link_button variant="outline" navigate={~p"/settings/integrations/ical"}>
            Settings
          </.link_button>
        </div>
      </div>
    </div>

    <.modal id="ai-settings">
      <div class="focus-on-show">
        <.form :let={f} for={@ai_changeset} phx-submit="save_ai_integration">
          <div class="flex flex-col gap-y-4">
            <.input
              type="select"
              label="Model"
              field={f[:external_id]}
              name="general_model"
              value={f.data.settings["general_model"]}
              options={[
                {"Claude Opus 4", "claude-opus-4-20250514"},
                {"Claude Sonnet 4", "claude-sonnet-4-20250514"},
                {"Claude Sonnet 3.7", "claude-3-7-sonnet-20250219"},
                {"Claude Haiku 3.5", "claude-3-5-haiku-20241022"},
                {"Gemini 2.5 Pro Preview", "gemini-2.5-pro-preview-06-05"},
                {"Gemini 2.5 Flash Preview", "gemini-2.5-flash-preview-05-20"},
                {"Gemini 2.0 Flash-Lite", "gemini-2.0-flash-lite"},
                {"Gemini 2.0 Flash", "gemini-2.0-flash"}
              ]}
            />
            <.input label="API key" field={f[:access_token]} />
          </div>
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#ai-settings")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button>Save</.button>
          </div>
        </.form>
      </div>
    </.modal>

    <.modal id="slack-settings" size="medium">
      <div class="focus-on-show">
        <div class="mb-8 flex flex-col items-center gap-y-3">
          <svg
            viewbox="0 0 498 127"
            width="498"
            height="127"
            xmlns="http://www.w3.org/2000/svg"
            class="h-10 w-fit"
          >
            <g fill="none">
              <path
                d="M159.5 99.5l6.2-14.4c6.7 5 15.6 7.6 24.4 7.6 6.5 0 10.6-2.5 10.6-6.3-.1-10.6-38.9-2.3-39.2-28.9-.1-13.5 11.9-23.9 28.9-23.9 10.1 0 20.2 2.5 27.4 8.2L212 56.5c-6.6-4.2-14.8-7.2-22.6-7.2-5.3 0-8.8 2.5-8.8 5.7.1 10.4 39.2 4.7 39.6 30.1 0 13.8-11.7 23.5-28.5 23.5-12.3 0-23.6-2.9-32.2-9.1m237.9-19.6c-3.1 5.4-8.9 9.1-15.6 9.1-9.9 0-17.9-8-17.9-17.9 0-9.9 8-17.9 17.9-17.9 6.7 0 12.5 3.7 15.6 9.1l17.1-9.5c-6.4-11.4-18.7-19.2-32.7-19.2-20.7 0-37.5 16.8-37.5 37.5s16.8 37.5 37.5 37.5c14.1 0 26.3-7.7 32.7-19.2l-17.1-9.5zM228.8 2.5h21.4v104.7h-21.4zm194.1 0v104.7h21.4V75.8l25.4 31.4h27.4l-32.3-37.3 29.9-34.8h-26.2L444.3 64V2.5zM313.8 80.1c-3.1 5.1-9.5 8.9-16.7 8.9-9.9 0-17.9-8-17.9-17.9 0-9.9 8-17.9 17.9-17.9 7.2 0 13.6 4 16.7 9.2v17.7zm0-45v8.5c-3.5-5.9-12.2-10-21.3-10-18.8 0-33.6 16.6-33.6 37.4 0 20.8 14.8 37.6 33.6 37.6 9.1 0 17.8-4.1 21.3-10v8.5h21.4v-72h-21.4z"
                fill="#FFF"
              /><path
                d="M27.2 80c0 7.3-5.9 13.2-13.2 13.2C6.7 93.2.8 87.3.8 80c0-7.3 5.9-13.2 13.2-13.2h13.2V80zm6.6 0c0-7.3 5.9-13.2 13.2-13.2 7.3 0 13.2 5.9 13.2 13.2v33c0 7.3-5.9 13.2-13.2 13.2-7.3 0-13.2-5.9-13.2-13.2V80z"
                fill="#E01E5A"
              /><path
                d="M47 27c-7.3 0-13.2-5.9-13.2-13.2C33.8 6.5 39.7.6 47 .6c7.3 0 13.2 5.9 13.2 13.2V27H47zm0 6.7c7.3 0 13.2 5.9 13.2 13.2 0 7.3-5.9 13.2-13.2 13.2H13.9C6.6 60.1.7 54.2.7 46.9c0-7.3 5.9-13.2 13.2-13.2H47z"
                fill="#36C5F0"
              /><path
                d="M99.9 46.9c0-7.3 5.9-13.2 13.2-13.2 7.3 0 13.2 5.9 13.2 13.2 0 7.3-5.9 13.2-13.2 13.2H99.9V46.9zm-6.6 0c0 7.3-5.9 13.2-13.2 13.2-7.3 0-13.2-5.9-13.2-13.2V13.8C66.9 6.5 72.8.6 80.1.6c7.3 0 13.2 5.9 13.2 13.2v33.1z"
                fill="#2EB67D"
              /><path
                d="M80.1 99.8c7.3 0 13.2 5.9 13.2 13.2 0 7.3-5.9 13.2-13.2 13.2-7.3 0-13.2-5.9-13.2-13.2V99.8h13.2zm0-6.6c-7.3 0-13.2-5.9-13.2-13.2 0-7.3 5.9-13.2 13.2-13.2h33.1c7.3 0 13.2 5.9 13.2 13.2 0 7.3-5.9 13.2-13.2 13.2H80.1z"
                fill="#ECB22E"
              />
            </g>
          </svg>
        </div>

        <.form :let={f} for={@slack_changeset} phx-submit="save_slack_integration">
          <div class="flex flex-col gap-y-4">
            <%!-- <.input label="App-level token" field={f[:app_level_token]} />
            <span class="text-alpha-64 -mt-4 text-xs">
              An app level token is optional but enables interactive features such as approving queries from Slack. This can be created from the Basic Information section of your Slack app.
            </span> --%>
            <.input label="Bot token" field={f[:bot_token]} />
            <span class="text-alpha-64 -mt-4 text-xs">
              A bot token is required for sending messages to Slack. This can be created from the Install App section of your Slack app.
            </span>
          </div>
          <div class="mt-3">
            <.button
              :if={!@show_slack_instructions}
              type="button"
              variant="text"
              phx-click="toggle_instructions"
            >
              Show setup instructions
            </.button>
          </div>
          <div :if={@show_slack_instructions}>
            <.link_button href="https://api.slack.com/apps?new_app=1" target="_blank" variant="text">
              https://api.slack.com/apps?new_app=1
            </.link_button>

            <div class="text-alpha-64 mt-4 text-sm">
              Step 1: Choose "From a manifest".
            </div>

            <div class="text-alpha-64 mt-4 text-sm">
              Step 2: Select your workspace.
            </div>

            <div class="text-alpha-64 mt-4 text-sm">
              Step 3: Paste the manifest below into the editor.
            </div>

            <div class="text-alpha-64 mt-4 text-sm">
              Step 4 (optional): Upload this image as the app icon.
            </div>
            <img src="/images/logo.png" alt="Devhub Logo" class="size-16 mt-2" />

            <div class="text-alpha-64 mt-4 text-sm">
              Step 5: Invite the bot to any channels you want to post to: "/invite @Devhub"
            </div>

            <div class="text-alpha-64 mt-4 text-sm">
              Manifest
            </div>
            <div class="bg-surface-3 mt-2 mb-6 flex items-start justify-between rounded-lg p-4">
              <div class="mr-2 overflow-x-scroll">
                <pre class="break-all">{@slack_manifest}</pre>
              </div>
              <div class="min-w-5">
                <copy-button value={@slack_manifest} />
              </div>
            </div>
          </div>
          <div class="mt-4 grid grid-cols-2 gap-4">
            <.button
              type="button"
              variant="secondary"
              phx-click={JS.exec("data-cancel", to: "#slack-settings")}
              aria-label={gettext("close")}
            >
              Cancel
            </.button>
            <.button>Save</.button>
          </div>
        </.form>
      </div>
    </.modal>
    """
  end

  def handle_event("save_ai_integration", params, socket) do
    %{organization: organization, integrations: integrations} = socket.assigns

    attrs =
      params["integration"]
      |> Map.put("provider", :ai)
      |> Map.put("settings", %{
        "general_model" => params["general_model"],
        "query_model" => params["query_model"]
      })
      |> Map.put("organization_id", organization.id)

    {:ok, _integration} =
      integrations
      |> Enum.find(%Integration{}, &(&1.provider == :ai))
      |> Integrations.insert_or_update(attrs)

    {:noreply, push_navigate(socket, to: ~p"/settings/integrations")}
  end

  def handle_event("save_slack_integration", %{"integration" => params}, socket) do
    %{organization: organization, slack: slack} = socket.assigns
    attrs = %{organization_id: organization.id, access_token: Jason.encode!(params)}

    {:ok, _integration} = Integrations.insert_or_update(slack, attrs)

    {:noreply, push_navigate(socket, to: ~p"/settings/integrations")}
  end

  def handle_event("toggle_instructions", _params, socket) do
    socket |> assign(:show_slack_instructions, !socket.assigns.show_slack_instructions) |> noreply()
  end
end
