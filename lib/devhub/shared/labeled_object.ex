defmodule Devhub.Shared.Schemas.LabeledObject do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.Shared.Schemas.Label
  alias Devhub.Users.Schemas.Organization

  @type t :: %__MODULE__{
          label_id: String.t(),
          saved_query_id: String.t() | nil,
          organization_id: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "lo"}
  schema "labeled_objects" do
    belongs_to :label, Label
    belongs_to :saved_query, SavedQuery
    belongs_to :organization, Organization

    timestamps()
  end

  def create_changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [:label_id, :saved_query_id, :organization_id])
    |> validate_required([:label_id, :organization_id])
  end
end
