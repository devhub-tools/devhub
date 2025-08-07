defmodule Devhub.Integrations.GitHub.Repository do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          name: String.t(),
          owner: String.t(),
          pushed_at: DateTime.t(),
          enabled: boolean(),
          archived: boolean()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "repo"}
  schema "repositories" do
    field :name, :string
    field :owner, :string
    field :default_branch, :string
    field :pushed_at, :utc_datetime
    field :enabled, :boolean, default: false
    field :archived, :boolean, default: false

    belongs_to :organization, Devhub.Users.Schemas.Organization

    timestamps()
  end

  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:name, :owner, :pushed_at, :enabled, :archived, :organization_id, :default_branch])
    |> validate_required([:name, :owner, :pushed_at, :organization_id, :default_branch])
    |> unique_constraint([:organization_id, :name, :owner])
  end
end
