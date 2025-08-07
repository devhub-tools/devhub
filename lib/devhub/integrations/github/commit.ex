defmodule Devhub.Integrations.GitHub.Commit do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          sha: String.t(),
          message: String.t(),
          authored_at: DateTime.t(),
          additions: integer() | nil,
          deletions: integer() | nil,
          on_default_branch: boolean()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "cmit"}
  schema "commits" do
    field :sha, :string
    field :message, :string
    field :authored_at, :utc_datetime
    field :additions, :integer
    field :deletions, :integer
    field :on_default_branch, :boolean, default: false

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :repository, Devhub.Integrations.GitHub.Repository
    has_many :authors, Devhub.Integrations.GitHub.CommitAuthor

    timestamps()
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [
      :sha,
      :message,
      :repository_id,
      :authored_at,
      :organization_id,
      :additions,
      :deletions,
      :on_default_branch
    ])
    |> validate_required([:sha, :repository_id, :organization_id, :on_default_branch])
    |> unique_constraint([:repository_id, :sha])
  end
end
