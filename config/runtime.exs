import Config

if Config.config_env() == :dev, do: Dotenv.load!()

defmodule Secret do
  @moduledoc false
  def read(name, default \\ nil) do
    case File.read("/etc/secrets/" <> name) do
      {:ok, value} ->
        value

      _error ->
        [_context, name] = String.split(name, "/")
        System.get_env(name, default)
    end
  end
end

with {:ok, file} <- File.read("/etc/secrets/app/agent-config.json"),
     {:ok, config} <- Jason.decode(file) do
  Application.put_env(:devhub, :agent_config, config)
end

host = System.get_env("APP_HOST") || "devhub.local"
pod_namespace = System.get_env("POD_NAMESPACE") || "devhub"

port =
  case config_env() do
    :test -> 4002
    _env -> String.to_integer(System.get_env("PORT") || "4000")
  end

{public_key, private_key} = :crypto.generate_key(:ecdh, :secp256r1)
named_curve = :pubkey_cert_records.namedCurves(:secp256r1)

default_signing_key =
  :public_key.pem_encode([
    :public_key.pem_entry_encode(
      :ECPrivateKey,
      {:ECPrivateKey, 1, private_key, {:namedCurve, named_curve}, public_key, :asn1_NOVALUE}
    )
  ])

k8s_ca_cert =
  case config_env() do
    :prod ->
      "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

    :test ->
      "/priv/cert/k8s-ca.crt"

    _env ->
      {cert, 0} =
        System.cmd(
          "kubectl",
          [
            "config",
            "view",
            "--raw",
            "--minify",
            "--flatten",
            "-o",
            "jsonpath={.clusters[].cluster.certificate-authority-data}"
          ],
          env: []
        )

      cert_path = Path.join(System.tmp_dir!(), "k8s-ca.crt")
      File.write!(cert_path, Base.decode64!(cert))
      cert_path
  end

config :devhub, Devhub.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1",
       key: Base.decode64!(Secret.read("app/CLOAK_KEY_V1", "am+/PVwB7BYjztMTZRE+di3WTFqgeAeCijpORDwBWZY="))}
  ]

config :devhub, DevhubWeb.Endpoint, http: [port: port]

config :devhub,
  issuer: "https://#{host}",
  agent: System.get_env("AGENT") == "true",
  cloud_hosted?: File.exists?("/etc/secrets/app/CLOUD_HOSTED"),
  auth_email_header: System.get_env("AUTH_EMAIL_HEADER"),
  auth_groups_header: System.get_env("AUTH_GROUPS_HEADER"),
  namespace: pod_namespace,
  signing_key: Secret.read("app/SIGNING_KEY", default_signing_key),
  k8s_ca_cert: k8s_ca_cert,
  proxy_tls_cert_file:
    if(File.exists?("/etc/secrets/proxy/tls.crt"),
      do: "/etc/secrets/proxy/tls.crt",
      else: "#{:code.priv_dir(:devhub)}/cert/selfsigned.pem"
    ),
  proxy_tls_key_file:
    if(File.exists?("/etc/secrets/proxy/tls.key"),
      do: "/etc/secrets/proxy/tls.key",
      else: "#{:code.priv_dir(:devhub)}/cert/selfsigned_key.pem"
    )

if System.get_env("ENABLE_TELEMETRY") != "true" do
  config :opentelemetry, traces_exporter: :none
end

config :wax_,
  origin: (config_env() == :prod && "https://#{host}") || "http://localhost:4000",
  rp_id: :auto,
  metadata_dir: "priv/fido2_metadata/"

if config_env() == :prod do
  ssl = System.get_env("DB_SSL")

  ssl_opts =
    Enum.reject(
      [
        cacertfile: if(File.exists?("/etc/secrets/ca/ca.crt"), do: "/etc/secrets/ca/ca.crt"),
        keyfile: if(File.exists?("/etc/secrets/client-cert/tls.key"), do: "/etc/secrets/client-cert/tls.key"),
        certfile: if(File.exists?("/etc/secrets/client-cert/tls.crt"), do: "/etc/secrets/client-cert/tls.crt"),
        verify: (ssl == "verify" && :verify_peer) || :verify_none
      ],
      fn {_k, v} -> is_nil(v) end
    )

  config :devhub, Devhub.Repo,
    ssl: if(ssl in ["true", "verify", "require"], do: ssl_opts, else: false),
    database: Secret.read("db/dbname", "devhub"),
    hostname: Secret.read("db/host"),
    username: Secret.read("db/user"),
    password: Secret.read("db/password"),
    port: String.to_integer(Secret.read("db/port") || "5432"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :devhub, DevhubWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    secret_key_base: Secret.read("app/SECRET_KEY_BASE"),
    server: true

  config :sentry,
    dsn: "https://ecfbbb89735447929575b479da06bd0f@errors.devhub.tools/1",
    environment_name: host
end
