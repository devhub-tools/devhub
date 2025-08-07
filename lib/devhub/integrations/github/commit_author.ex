defmodule Devhub.Integrations.GitHub.CommitAuthor do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          commit_id: String.t(),
          github_user_id: String.t()
        }

  @primary_key false
  schema "commit_authors" do
    belongs_to :commit, Devhub.Integrations.GitHub.Commit
    belongs_to :github_user, Devhub.Integrations.GitHub.User
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:github_user_id, :commit_id])
    |> validate_required([:github_user_id, :commit_id])
    |> foreign_key_constraint(:commit_id)
    |> foreign_key_constraint(:github_user_id)
  end
end
