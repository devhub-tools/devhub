defmodule Devhub.Integrations.Schemas.Integration do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          provider: :github | :linear | :ical,
          external_id: String.t(),
          access_token: String.t() | nil
        }

  @redact Application.compile_env(:devhub, :compile_env) != :test

  @primary_key {:id, UXID, autogenerate: true, prefix: "int"}
  schema "integrations" do
    field :provider, Ecto.Enum, values: [:github, :linear, :ical, :ai, :slack]
    field :external_id, :string
    field :access_token, Devhub.Types.EncryptedBinary, redact: @redact
    field :settings, :map

    belongs_to :organization, Devhub.Users.Schemas.Organization

    timestamps()
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:external_id, :access_token, :provider, :organization_id, :settings])
    |> validate_required([:organization_id, :provider])
    |> unique_constraint([:organization_id, :provider])
  end
end
