import Config

config :devhub, Devhub.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "devhub_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :devhub, DevhubWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qELxQ4fvJnCBCQsBBwsiuQZaistOmNMJ2HA9LRdLLXXbm6Q4rVA3dKzJd1WQtkL+",
  server: true

config :devhub, DevhubWeb.PostgresProxy, port: 54_321
config :devhub, Oban, testing: :manual

# Enable dev routes for dashboard and mailbox
config :devhub, dev_routes: true

config :junit_formatter,
  report_file: "elixir.xml",
  report_dir: "junit/",
  automatic_create_dir?: true,
  print_report_file: true,
  include_filename?: true

# Print only warnings and errors during test
config :logger, level: :info

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
