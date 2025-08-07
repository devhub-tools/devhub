defmodule Devhub.QueryDesk.Schemas.DatabaseColumn do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.QueryDesk.Schemas.DataProtectionColumn

  @type t :: %__MODULE__{
          name: String.t(),
          table: String.t(),
          type: String.t(),
          fkey_column_name: String.t(),
          fkey_table_name: String.t(),
          is_primary_key: boolean(),
          position: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "col"}
  schema "querydesk_database_columns" do
    field :name, :string
    field :table, :string
    field :type, :string
    field :fkey_column_name, :string
    field :fkey_table_name, :string
    field :is_primary_key, :boolean, default: false
    field :position, :integer

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :database, Database

    has_many :data_protection_column, DataProtectionColumn, foreign_key: :column_id, on_delete: :delete_all

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [
      :name,
      :table,
      :type,
      :fkey_column_name,
      :fkey_table_name,
      :is_primary_key,
      :organization_id,
      :database_id,
      :position
    ])
    |> validate_required([
      :name,
      :table,
      :type,
      :is_primary_key,
      :organization_id,
      :database_id
    ])
  end
end
