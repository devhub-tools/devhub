defmodule Devhub.Integrations.GitHub.User do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          username: String.t() | nil
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "gh_usr"}
  schema "github_users" do
    field :username, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
    has_one :organization_user, Devhub.Users.Schemas.OrganizationUser, foreign_key: :github_user_id

    many_to_many :commits, Devhub.Integrations.GitHub.Commit,
      join_through: "commit_authors",
      join_keys: [github_user_id: :id, commit_id: :id]
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:username, :organization_id])
    |> unique_constraint([:organization_id, :username])
  end
end
