import Config

config :devhub, Devhub.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "devhub_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :devhub, DevhubWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "SnpCXfRF6GXwHVllfPNicC2jUD2dESDAtzyKvosHkit1PD2q/jTDWeGPT2b0cBkz",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:devhub, ~w(--sourcemap=inline --watch)]},
    storybook_tailwind: {Tailwind, :install_and_run, [:storybook, ~w(--watch)]},
    tailwind: {Tailwind, :install_and_run, [:devhub, ~w(--watch)]}
  ]

config :devhub, DevhubWeb.Endpoint,
  live_reload: [
    # Enable `:phoenix_live_reload` Browser errors
    # https://fly.io/phoenix-files/phoenix-dev-blog-server-logs-in-the-browser-console/
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/devhub_web/(controllers|live|components)/.*(ex|heex)$",
      ~r"storybook/.*(exs)$"
    ]
  ]

config :devhub,
  dev_routes: true,
  licensing_base_url: "https://licensing-staging.devhub.cloud",
  login_url: "https://auth-staging.devhub.cloud/login"

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :plug_init_mode, :runtime
config :phoenix, :stacktrace_depth, 20

config :phoenix_live_view, :debug_heex_annotations, true
