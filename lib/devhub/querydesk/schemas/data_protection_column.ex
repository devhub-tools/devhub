defmodule Devhub.QueryDesk.Schemas.DataProtectionColumn do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.DataProtectionAction

  @type t :: %__MODULE__{
          action: :show | :hide | :json | :custom
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "dpc"}
  schema "data_protection_columns" do
    field :action, Ecto.Enum, values: [:show, :hide, :json, :custom], default: :hide

    belongs_to :custom_action, DataProtectionAction
    belongs_to :policy, Devhub.QueryDesk.Schemas.DataProtectionPolicy
    belongs_to :column, Devhub.QueryDesk.Schemas.DatabaseColumn
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [
      :action,
      :custom_action_id,
      :policy_id,
      :column_id
    ])
    |> validate_required([
      :action,
      :policy_id,
      :column_id
    ])
    |> unique_constraint([:policy_id, :column_id], error_key: :column_id)
  end
end
