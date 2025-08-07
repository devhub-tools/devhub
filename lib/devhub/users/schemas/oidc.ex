defmodule Devhub.Users.OIDC do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Users.Schemas.Organization

  @type t :: %__MODULE__{
          discovery_document_uri: String.t(),
          client_id: String.t(),
          client_secret: String.t()
        }

  @redact Application.compile_env(:devhub, :compile_env) != :test

  @primary_key {:id, UXID, autogenerate: true, prefix: "oidc"}
  schema "oidc_configs" do
    field :discovery_document_uri, :string
    field :client_id, :string
    field :client_secret, Devhub.Types.EncryptedBinary, redact: @redact

    belongs_to :organization, Organization

    timestamps()
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, [:organization_id, :discovery_document_uri, :client_id, :client_secret])
    |> validate_required([:organization_id])
  end
end
