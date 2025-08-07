# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

alias Tesla.Adapter.Finch

crontab =
  [
    {"* * * * *", Devhub.TerraDesk.Jobs.RunDriftDetection, queue: :terradesk},
    {"* * * * *", Devhub.Workflows.Jobs.RunScheduledWorkflows, queue: :workflows},
    {"0 * * * *", Devhub.Calendar.SyncJob, queue: :calendar},
    {"0 * * * *", Devhub.Uptime.Jobs.Cron, queue: :uptime},
    {"0 0 * * *", Devhub.Integrations.GitHub.ImportCron, queue: :github},
    {"0 0 * * *", Devhub.Integrations.Linear.ImportCron, queue: :linear},
    {"0 0 * * *", Devhub.QueryDesk.Jobs.CleanupExpiredSharedQueries, queue: :querydesk}
  ]

config :devhub, Devhub.Repo,
  migration_primary_key: [type: :text],
  migration_timestamps: [type: :utc_datetime_usec],
  start_apps_before_migration: [:logger_json],
  telemetry_prefix: [:devhub, :repo]

# Configures the endpoint
config :devhub, DevhubWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: DevhubWeb.ErrorHTML, json: DevhubWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Devhub.PubSub,
  live_view: [signing_salt: "Ka2S3KAh"]

config :devhub, DevhubWeb.PostgresProxy, port: 54_320

config :devhub, Oban,
  notifier: Oban.Notifiers.PG,
  queues: [
    calendar: 1,
    github: 1,
    licensing: 1,
    linear: 1,
    querydesk: 1,
    terradesk: 50,
    uptime: 20,
    workflows: 10
  ],
  repo: Devhub.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Lifeline, rescue_after: to_timeout(hour: 1)},
    {Oban.Plugins.Cron, crontab: crontab}
  ],
  shutdown_grace_period: to_timeout(second: 120)

config :devhub,
  compile_env: config_env(),
  licensing_base_url: "https://licensing.devhub.cloud",
  login_url: "https://auth.devhub.cloud/login",
  namespace: Devhub,
  ecto_repos: [Devhub.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  devhub: [
    args:
      ~w(js/app.js js/storybook.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  backends: [:console]

config :o11y, :attribute_namespace, "devhub"

config :oauth2, adapter: {Finch, name: Devhub.Finch}

config :phoenix,
  json_library: Jason,
  static_compressors: [
    PhoenixBakery.Gzip,
    PhoenixBakery.Brotli
  ]

config :sentry,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  devhub: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ],
  storybook: [
    args: ~w(
          --config=tailwind.config.js
          --input=css/storybook.css
          --output=../priv/static/assets/storybook.css
        ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :tesla, :adapter, {Finch, name: Devhub.Finch}
config :tesla, disable_deprecated_builder_warning: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
