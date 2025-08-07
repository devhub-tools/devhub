defmodule Devhub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Devhub.Licensing.Client
  alias Devhub.Uptime.RequestTracerService

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{})
    # Oban.Telemetry.attach_default_logger()

    OpentelemetryEcto.setup([:devhub, :repo])
    OpentelemetryOban.setup()

    OpentelemetryBandit.setup()
    OpentelemetryPhoenix.setup(adapter: :bandit)

    :ets.new(DevhubWeb.AgentConnection, [:set, :named_table, :public])

    is_agent? = System.get_env("AGENT") == "true"
    compile_env = Application.get_env(:devhub, :compile_env)

    children = [
      {Devhub.Coverbot.Cache, not is_agent?},
      {Devhub.Portal.Cache, not is_agent?},
      {Devhub.QueryDesk.Cache, not is_agent?},
      {Task.Supervisor, name: Devhub.TaskSupervisor},
      {Finch, name: Devhub.Finch},
      {Finch,
       name: Devhub.Finch.K8s,
       pools: %{
         default: [
           conn_opts: [
             transport_opts: [
               cacertfile: Application.get_env(:devhub, :k8s_ca_cert)
             ]
           ]
         ]
       }},
      {Devhub.QueryDesk.QueryParserService, not is_agent?},
      {:poolboy.child_spec(:request_tracer_service_worker, poolboy_config()), not is_agent?},
      Devhub.Vault,
      DevhubWeb.Telemetry,
      {Devhub.Repo, not is_agent?},
      {{Oban, Application.fetch_env!(:devhub, Oban)}, not is_agent?},
      {Devhub.TerraDesk.TerraformStateCache, not is_agent?},
      {Phoenix.PubSub, name: Devhub.PubSub},
      {Registry, keys: :unique, name: Devhub.QueryDesk.RepoRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Devhub.QueryDesk.RepoSupervisor},
      DevhubWeb.Endpoint,
      {{LiveSync, [repo: Devhub.Repo, otp_app: :devhub]}, not is_agent?},
      {Supervisor.child_spec({Task, &DevhubWeb.PostgresProxy.accept/0},
         id: :postgres,
         restart: :permanent
       ), not is_agent?},
      {Task.child_spec(fn ->
         # update installation details on startup
         Client.update_installation(Devhub.Users.get_organization())
       end), not is_agent? and compile_env != :test},
      {Devhub.Agents.Client, is_agent?}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Devhub.Supervisor]

    children
    |> Enum.map(fn
      {child, true} -> child
      {_child, false} -> nil
      child -> child
    end)
    |> Enum.reject(&is_nil/1)
    |> Supervisor.start_link(opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DevhubWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp poolboy_config do
    [
      name: {:local, :request_tracer_service_worker},
      worker_module: RequestTracerService,
      size: 5,
      max_overflow: 10
    ]
  end
end
