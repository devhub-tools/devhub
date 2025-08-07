defmodule Devhub.Users.Schemas.Passkey do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Types.EncryptedBinary

  @type t :: %__MODULE__{
          id: String.t(),
          raw_id: String.t(),
          public_key: binary(),
          aaguid: binary(),
          user_id: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "pass"}
  schema "passkeys" do
    field :raw_id, :string
    field :public_key, EncryptedBinary
    field :aaguid, :binary

    belongs_to :user, Devhub.Users.User

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [:raw_id, :public_key, :aaguid, :user_id])
    |> validate_required([:raw_id, :public_key, :user_id])
  end
end
