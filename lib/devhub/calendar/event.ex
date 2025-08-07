defmodule Devhub.Calendar.Event do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          external_id: String.t() | nil,
          person: String.t() | nil,
          start_date: Date.t(),
          end_date: Date.t(),
          title: String.t(),
          color: String.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "evt"}
  schema "calendar_events" do
    field :external_id, :string
    field :person, :string
    field :start_date, :date
    field :end_date, :date
    field :title, :string
    field :color, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :linear_user, Devhub.Integrations.Linear.User
  end

  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [
      :external_id,
      :color,
      :person,
      :start_date,
      :end_date,
      :organization_id,
      :title,
      :linear_user_id
    ])
    |> validate_required([:title, :color])
    |> unique_constraint([:organization_id, :external_id])
  end
end
