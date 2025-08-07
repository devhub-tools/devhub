defmodule Devhub.TerraDesk.Schemas.WorkloadIdentity do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.TerraDesk.Schemas.Workspace
  alias Devhub.Users.Schemas.Organization

  @derive {Jason.Encoder, only: [:enabled, :service_account_email, :provider]}

  @type t :: %__MODULE__{
          id: String.t(),
          enabled: boolean(),
          service_account_email: String.t(),
          provider: String.t(),
          workspace_id: String.t(),
          workspace: Workspace.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "gwi"}
  schema "google_workload_identities" do
    field :enabled, :boolean
    field :service_account_email, :string
    field :provider, :string

    belongs_to :organization, Organization
    belongs_to :workspace, Workspace

    timestamps()
  end

  def changeset(google_workload_identity \\ %__MODULE__{}, params) do
    google_workload_identity
    |> cast(params, [:service_account_email, :provider, :enabled, :organization_id])
    |> cast_assoc(:workspace, with: &Workspace.changeset/2)
  end
end
