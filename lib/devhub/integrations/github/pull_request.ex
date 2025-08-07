defmodule Devhub.Integrations.GitHub.PullRequest do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          number: integer(),
          title: String.t(),
          state: String.t(),
          additions: integer() | nil,
          deletions: integer() | nil,
          changed_files: integer() | nil,
          comments_count: integer() | nil,
          author: String.t(),
          is_draft: boolean(),
          first_commit_authored_at: DateTime.t() | nil,
          opened_at: DateTime.t() | nil,
          merged_at: DateTime.t() | nil
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "pr"}
  schema "pull_requests" do
    field :number, :integer
    field :title, :string
    field :state, :string
    field :additions, :integer
    field :deletions, :integer
    field :changed_files, :integer
    field :comments_count, :integer
    field :is_draft, :boolean
    field :first_commit_authored_at, :utc_datetime
    field :opened_at, :utc_datetime
    field :merged_at, :utc_datetime

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :repository, Devhub.Integrations.GitHub.Repository
    belongs_to :github_user, Devhub.Integrations.GitHub.User, foreign_key: :author, references: :username
    has_many :reviews, Devhub.Integrations.GitHub.PullRequestReview

    timestamps()
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [
      :number,
      :title,
      :repository_id,
      :state,
      :additions,
      :deletions,
      :changed_files,
      :comments_count,
      :author,
      :is_draft,
      :first_commit_authored_at,
      :opened_at,
      :merged_at,
      :organization_id
    ])
    |> validate_required([
      :number,
      :title,
      :repository_id,
      :state,
      :author,
      :is_draft,
      :organization_id
    ])
    |> unique_constraint([:repository_id, :number])
  end
end
