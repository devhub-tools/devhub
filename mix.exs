defmodule Devhub.MixProject do
  use Mix.Project

  def project do
    [
      app: :devhub,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      releases: [
        devhub: [
          applications: [
            opentelemetry_exporter: :permanent,
            opentelemetry: :temporary
          ]
        ]
      ],
      aliases: aliases(),
      deps: deps(),
      test_paths: ["lib"],
      test_coverage: [tool: ExCoveralls, export: "excoveralls"],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Devhub.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:abacus, "~> 2.1"},
      {:bandit, "~> 1.2"},
      {:brotli, github: "tellerhq/erl-brotli", branch: "master", override: true},
      {:cloak_ecto, github: "michaelst/cloak_ecto", branch: "embedded-binaries"},
      # pr to support embedded binaries https://github.com/danielberkompas/cloak_ecto/pull/60
      # {:cloak_ecto, "~> 1.2"},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:decorator, "~> 1.4"},
      {:dotenv, "~> 3.1", only: [:dev, :test]},
      {:ecto_ch, "~> 0.6.0"},
      {:ecto_sql, "~> 3.10"},
      {:ecto, "~> 3.12"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:ex_machina, "~> 2.7", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:finch, "~> 0.18"},
      {:floki, ">= 0.30.0"},
      {:geo_postgis, "~> 3.4"},
      {:gettext, "~> 0.20"},
      {:grpc, "~> 0.9"},
      {:jason, "~> 1.2"},
      {:joken, "~> 2.6"},
      {:junit_formatter, "~> 3.4", only: [:test]},
      {:live_sync, "~> 0.1"},
      {:logger_json, "~> 6.1"},
      {:mimic, "~> 1.0", only: :test},
      {:myxql, "~> 0.7"},
      {:nebulex, "~> 2.6"},
      {:oauth2, "~> 2.1"},
      {:oban_web, "~> 2.11"},
      {:oban, "~> 2.19"},
      {:open_telemetry_decorator, "~> 1.5"},
      {:openid_connect, github: "michaelst/openid_connect"},
      {:opentelemetry_bandit, "~> 0.2-rc"},
      {:opentelemetry_ecto, "~> 1.0"},
      {:opentelemetry_exporter, "~> 1.7"},
      {:opentelemetry_nebulex, "~> 0.1"},
      {:opentelemetry_oban, "~> 1.0"},
      {:opentelemetry_phoenix, "~> 2.0.0-rc.1"},
      {:opentelemetry_semantic_conventions, "~> 1.27", override: true},
      {:opentelemetry_tesla, "~> 2.4"},
      {:opentelemetry, "~> 1.4"},
      {:pgvector, "~> 0.3.0"},
      {:phoenix_bakery, "~> 0.1.0", runtime: false},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_storybook, "~> 0.8.0"},
      {:phoenix, "~> 1.7"},
      {:polymorphic_embed, "~> 5.0"},
      {:poolboy, "~> 1.5.1"},
      {:postgrex, ">= 0.0.0"},
      {:protobuf, "~> 0.13"},
      {:sentry, "~> 10.8"},
      {:styler, "~> 1.0", only: [:dev, :test], runtime: false},
      {:tailwind_formatter, "~> 0.4.2", only: [:dev, :test], runtime: false},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:tesla, "~> 1.8"},
      {:tidewave, "~> 0.1", only: :dev},
      {:timex, "~> 3.7"},
      {:uxid, "~> 0.2"},
      {:wax_, "~> 0.7"},
      {:websockex, "~> 0.4"},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.1.1", sparse: "optimized", app: false, compile: false, depth: 1}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind devhub", "esbuild devhub"],
      "assets.deploy": [
        "tailwind devhub --minify",
        "esbuild devhub --minify",
        "tailwind storybook --minify",
        "phx.digest"
      ]
    ]
  end
end
