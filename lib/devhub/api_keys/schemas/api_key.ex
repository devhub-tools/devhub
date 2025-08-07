defmodule Devhub.ApiKeys.Schemas.ApiKey do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Users.Schemas.Organization

  @type t :: %__MODULE__{
          name: String.t(),
          selector: binary(),
          verify_hash: binary(),
          expires_at: DateTime.t() | nil
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "key"}
  schema "api_keys" do
    field :name, :string
    field :selector, :binary
    field :verify_hash, :binary
    field :expires_at, :utc_datetime

    field :permissions, {:array, Ecto.Enum},
      values: [:full_access, :coverbot, :querydesk_limited, :trigger_workflows],
      default: []

    belongs_to :organization, Organization

    timestamps()
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:organization_id, :selector, :verify_hash, :expires_at, :name, :permissions])
    |> validate_required([:organization_id, :selector, :verify_hash, :name])
  end

  def update_changeset(session, attrs) do
    cast(session, attrs, [:expires_at, :name, :permissions])
  end
end
