[
  import_deps: [:ecto, :ecto_sql, :phoenix, :oban, :grpc, :polymorphic_embed],
  subdirectories: ["priv/*/migrations"],
  plugins: [TailwindFormatter, Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/*.exs", "storybook/**/*.exs"]
]
