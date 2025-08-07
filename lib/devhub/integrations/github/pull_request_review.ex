defmodule Devhub.Integrations.GitHub.PullRequestReview do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          github_id: String.t(),
          author: String.t(),
          reviewed_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "prr"}
  schema "pull_request_reviews" do
    field :github_id, :string
    field :author, :string
    field :reviewed_at, :utc_datetime

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :pull_request, Devhub.Integrations.GitHub.PullRequest
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [:github_id, :author, :reviewed_at, :pull_request_id, :organization_id])
    |> validate_required([:github_id, :author, :reviewed_at, :pull_request_id, :organization_id])
    |> unique_constraint([:pull_request_id, :github_id])
    |> foreign_key_constraint(:pull_request_id)
  end
end
