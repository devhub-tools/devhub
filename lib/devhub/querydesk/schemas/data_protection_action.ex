defmodule Devhub.QueryDesk.Schemas.DataProtectionAction do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.Database

  @type t :: %__MODULE__{
          name: String.t(),
          table: String.t(),
          action: :show | :hide | :json,
          condition: String.t(),
          join_through: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "dpa"}
  schema "data_protection_actions" do
    field :name, :string
    field :table, :string
    field :action, Ecto.Enum, values: [:show, :hide, :json], default: :hide
    field :condition, :string
    field :join_through, :string

    belongs_to :database, Database

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [:name, :table, :action, :condition, :join_through])
    |> unique_constraint([:database_id, :table, :name], error_key: :name)
  end
end
