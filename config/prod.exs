import Config

config :devhub, DevhubWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, :default_handler, formatter: {LoggerJSON.Formatters.Basic, []}

config :logger,
  backends: [Sentry.LoggerBackend]

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
