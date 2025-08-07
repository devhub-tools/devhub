defmodule Devhub.TerraDesk.Schemas.Secret do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.TerraDesk.Schemas.Workspace

  @derive {Jason.Encoder, only: [:id, :name]}

  @primary_key {:id, UXID, autogenerate: true, prefix: "tfsec"}
  schema "terraform_secrets" do
    field :name, :string
    field :value, Devhub.Types.EncryptedBinary, redact: true

    belongs_to :workspace, Workspace

    timestamps()
  end

  def changeset(secret \\ %__MODULE__{}, params) do
    secret
    |> cast(params, [:name, :value])
    |> validate_required([:name, :value])
  end
end
