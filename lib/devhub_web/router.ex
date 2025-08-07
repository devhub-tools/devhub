defmodule DevhubWeb.Router do
  use DevhubWeb, :router

  import Oban.Web.Router

  forward "/_health", HealthCheck

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DevhubWeb.Layouts, :root}
    plug :protect_from_forgery
    plug DevhubWeb.Plugs.ContentSecurityPolicy
    plug DevhubWeb.Middleware.LoadOrganization.Plug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :internal do
    plug DevhubWeb.Plugs.VerifyInternalKey
  end

  pipeline :authenticated_api do
    plug DevhubWeb.Plugs.VerifyApiKey
  end

  pipeline :authenticated do
    plug DevhubWeb.Middleware.EnsureAuthenticated.Plug
  end

  scope "/.well-known", DevhubWeb do
    get "/openid-configuration", WellKnownController, :discovery
    get "/jwks.json", WellKnownController, :jwks
  end

  ### product specific API routes
  scope "/api", DevhubWeb do
    pipe_through :api

    scope "/internal" do
      pipe_through :internal

      scope "/terradesk" do
        post "/upload-plan", TerraDeskController, :upload_plan
        get "/download-plan", TerraDeskController, :download_plan
      end
    end

    scope "/v1", V1 do
      scope "/" do
        pipe_through [:authenticated_api]

        resources "/users", UserController, only: [:show]

        if Code.ensure_loaded?(RoleController) do
          resources "/roles", RoleController, only: [:show]
        end
      end

      scope "/coverbot" do
        get "/:owner/:repo/:branch/badge.json", BadgeController, :coverage

        scope "/" do
          pipe_through [:authenticated_api]

          post "/coverage", CoverageController, :create
          post "/junit/:repo_owner/:repo/:sha", TestReportController, :junit
        end
      end

      scope "/dashboards" do
        pipe_through [:authenticated_api]

        resources "/", DashboardController, only: [:show, :create, :update, :delete]
      end

      scope "/querydesk" do
        pipe_through [:authenticated_api]

        put "/databases/setup", DatabaseController, :setup
        delete "/databases/remove/:api_id", DatabaseController, :delete
        resources "/databases", DatabaseController, only: [:show, :create, :update, :delete]
      end

      scope "/terradesk" do
        pipe_through [:authenticated_api]

        resources "/workspaces", WorkspaceController, only: [:show, :create, :update, :delete]
      end

      scope "/uptime" do
        get "/:id/uptime/:duration/badge.json", BadgeController, :uptime
        get "/:id/latency/:duration/badge.json", BadgeController, :response_time
        get "/:id/health/badge.json", BadgeController, :health
      end

      scope "/workflows" do
        pipe_through [:authenticated_api]

        post "/:id/run", WorkflowController, :run
        resources "/", WorkflowController, only: [:show, :create, :update, :delete]
      end
    end
  end

  ### unauthenticated routes
  scope "/", DevhubWeb do
    pipe_through :browser

    get "/license-expired", PageController, :license_expired
    get "/no-license", PageController, :no_license
    get "/not-authenticated", PageController, :not_authenticated

    scope "/auth" do
      get "/mfa", AuthController, :mfa
      post "/mfa", AuthController, :verify_mfa
      post "/mfa/setup", AuthController, :setup_mfa
      get "/logout", AuthController, :logout
      get "/callback", AuthController, :login
      get "/oidc", AuthController, :oidc_request
      get "/oidc/callback", AuthController, :oidc_callback
    end

    scope "/agents" do
      get "/socket", AgentController, :socket
    end
  end

  ### authenticated routes
  scope "/", DevhubWeb do
    pipe_through [:browser, :authenticated]

    if Code.ensure_loaded?(Licensing) do
      get "/start-trial/:plan", PageController, :start_trial
    end

    # coveralls-ignore-next-line
    oban_dashboard("/oban", csp_nonce_assign_key: :csp_nonce)

    scope "/github" do
      get "/setup-app", GitHubController, :setup_app
      get "/setup-installation", GitHubController, :setup_installation
    end

    scope "/ai" do
      post "/complete-query", AIController, :complete_query
    end

    scope "/agents" do
      get "/:id/config", AgentController, :config
    end
  end

  hooks =
    Enum.filter(
      [
        DevhubWeb.Middleware.LoadOrganization.Hook,
        DevhubWeb.Middleware.EnsureAuthenticated.Hook,
        DevhubWeb.Middleware.CheckPermissions.Hook,
        DevhubWeb.Middleware.CheckLicense.Hook,
        DevhubWeb.Middleware.Nav.Hook,
        DevhubWeb.Middleware.Events.Hook
      ],
      fn hook ->
        case Code.ensure_compiled(hook) do
          {:module, _module} -> true
          _error -> false
        end
      end
    )

  live_session :authenticated, on_mount: hooks do
    scope "/", DevhubWeb.Live do
      pipe_through [:browser, :authenticated]

      live "/", Portal.MyPortal

      scope "/portal", Portal do
        live "/metrics", Metrics
        live "/metrics/devs/:id", Dev
        live "/metrics/:chart/:date", ChartData
        live "/planning", Planning
      end

      scope "/dashboards", Dashboards do
        live "/", Home
        live "/:id", EditDashboard
        live "/:id/view", ViewDashboard
      end

      scope "/workflows", Workflows do
        live "/", Dashboard
        live "/:id/edit", EditWorkflow
        live "/:id", Workflow
        live "/:id/runs/:run_id", Run
      end

      scope "/settings", Settings do
        live "/account", Account
        live "/agents", Agents
        live "/api-keys", ApiKeys

        if Code.ensure_loaded?(Billing) do
          live "/billing", Billing
        end

        live "/integrations", Integrations
        live "/oidc", OIDC

        if Code.ensure_loaded?(Roles) do
          live "/roles", Roles
          live "/roles/:id", Role
        end

        live "/teams", Teams
        live "/users", Users
        live "/integrations/github", GitHubSettings
        live "/integrations/github/setup", GitHubSetup
        live "/integrations/linear", LinearSettings
        live "/integrations/linear/setup", LinearSetup
        live "/integrations/ical", Ical
      end

      # QueryDesk
      scope "/querydesk", QueryDesk do
        live "/", Databases
        live "/audit-log", AuditLog
        live "/library", Query, :library
        live "/shared-queries", SharedQueries
        live "/ai", Query, :ai
        live "/labels", Labels
        live "/plan/:id", QueryPlan

        if Code.ensure_loaded?(PendingQueries) do
          live "/pending-queries", PendingQueries
        end

        scope "/databases" do
          live "/:id/table/:table", Table
          live "/:id/:mode", Query
          live "/:id", DatabaseSettings

          if Code.ensure_loaded?(DataProtectionTable) do
            live "/:id/data-protection/:policy_id/:table", DataProtectionTable
          end

          if Code.ensure_loaded?(DataProtectionPolicy) do
            live "/:id/data-protection/:policy_id", DataProtectionPolicy
          end

          if Code.ensure_loaded?(DataProtectionPolicies) do
            live "/:id/data-protection", DataProtectionPolicies
          end
        end
      end

      # TerraDesk
      scope "/terradesk", TerraDesk do
        live "/", Workspaces
        live "/drift-detection", DriftDetection
        live "/workspaces/new", WorkspaceSettings
        live "/workspaces/:id/settings", WorkspaceSettings
        live "/workspaces/:id", Workspace
        live "/workspaces/:id/plan", TargetedPlan
        live "/plans/:plan_id", Plan
      end

      # Coverbot
      scope "/coverbot", Coverbot do
        live "/", Dashboard
        live "/test-reports", TestReports
        live "/:repository_id", Repository
        live "/coverage/:coverage_id", Coverage
      end

      # uptime
      scope "/uptime", Uptime do
        live "/", Dashboard
        live "/services/new", ServiceSettings
        live "/services/:id", Service
        live "/services/:id/settings", ServiceSettings
      end
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:devhub, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router
    import PhoenixStorybook.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DevhubWeb.Telemetry

      get "/login-as/:id", DevhubWeb.AuthController, :login_as
    end

    scope "/" do
      storybook_assets()
    end

    scope "/", DevhubWeb do
      pipe_through(:browser)
      live_storybook("/storybook", backend_module: DevhubWeb.Storybook)
    end
  end
end
