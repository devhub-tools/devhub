defmodule Devhub.Integrations.Schemas.GitHubApp do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Types.EncryptedBinary

  @type t :: %__MODULE__{
          external_id: integer(),
          slug: String.t(),
          client_id: String.t(),
          client_secret: String.t(),
          webhook_secret: String.t(),
          private_key: String.t(),
          organization_id: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @redact Application.compile_env(:devhub, :compile_env) != :test

  @primary_key {:id, UXID, autogenerate: true, prefix: "gha"}
  schema "github_apps" do
    field :external_id, :integer
    field :slug, :string
    field :client_id, :string
    field :client_secret, EncryptedBinary, redact: @redact
    field :webhook_secret, EncryptedBinary, redact: @redact
    field :private_key, EncryptedBinary, redact: @redact

    belongs_to :organization, Devhub.Users.Schemas.Organization

    timestamps()
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:external_id, :slug, :client_id, :client_secret, :webhook_secret, :private_key, :organization_id])
    |> unique_constraint([:organization_id])
  end
end
