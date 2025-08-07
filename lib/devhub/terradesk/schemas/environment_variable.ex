defmodule Devhub.TerraDesk.Schemas.EnvVar do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.TerraDesk.Schemas.Workspace

  @derive {Jason.Encoder, only: [:id, :name, :value]}

  @primary_key {:id, UXID, autogenerate: true, prefix: "tfenv"}
  schema "terraform_env_vars" do
    field :name, :string
    field :value, :string

    belongs_to :workspace, Workspace

    timestamps()
  end

  def changeset(env_var \\ %__MODULE__{}, params) do
    env_var
    |> cast(params, [:name, :value])
    |> validate_required([:name, :value])
  end
end
