# defmodule Devhub.Dashboards.Schemas.DashboardPanel do
#   @moduledoc false
#   use Devhub.Schema

#   import Ecto.Changeset

#   @type t :: %__MODULE__{
#           id: String.t(),
#           title: String.t(),
#           configuration: map(),
#           organization_id: String.t(),
#           dashboard_id: String.t(),
#           inserted_at: DateTime.t(),
#           updated_at: DateTime.t()
#         }

#   schema "dashboard_panels" do
#     field :title, :string
#     field :configuration, :map

#     belongs_to :organization, Devhub.Users.Schemas.Organization
#     belongs_to :dashboard, Devhub.Dashboards.Schemas.Dashboard

#     timestamps()
#   end

#   def changeset(schema \\ %__MODULE__{}, attrs) do
#     schema
#     |> cast(attrs, [:title, :configuration, :organization_id, :dashboard_id])
#     |> validate_required([:title, :configuration, :organization_id, :dashboard_id])
#   end
# end
