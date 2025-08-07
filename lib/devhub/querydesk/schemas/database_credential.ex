defmodule Devhub.QueryDesk.Schemas.DatabaseCredential do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.Types.EncryptedBinary

  @type t :: %__MODULE__{
          hostname: String.t() | nil,
          username: String.t(),
          password: String.t(),
          reviews_required: integer(),
          default_credential: boolean()
        }

  @derive {Jason.Encoder,
           only: [
             :id,
             :hostname,
             :username,
             :reviews_required,
             :default_credential
           ]}

  @redact Application.compile_env(:devhub, :compile_env) != :test

  @primary_key {:id, UXID, autogenerate: true, prefix: "crd"}
  schema "querydesk_active_database_credentials" do
    field :hostname, :string
    field :position, :integer
    field :username, :string
    field :password, EncryptedBinary, redact: @redact
    field :reviews_required, :integer, default: 0
    field :default_credential, :boolean, default: false

    belongs_to :database, Database

    timestamps()
  end

  def changeset(struct, params, position) do
    struct
    |> cast(params, [:hostname, :username, :password, :reviews_required, :default_credential])
    |> change(position: position)
    |> unique_constraint([:database_id, :username],
      error_key: :username,
      message: "already setup for this database",
      name: :querydesk_database_credentials_database_id_username_index
    )
    |> unique_constraint([:database_id, :default_credential], name: :unique_default_credential)
  end
end
