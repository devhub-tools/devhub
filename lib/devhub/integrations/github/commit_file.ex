defmodule Devhub.Integrations.GitHub.CommitFile do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          filename: String.t(),
          extension: String.t(),
          additions: integer(),
          deletions: integer(),
          patch: String.t() | nil,
          status: String.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "cmf"}
  schema "commit_files" do
    field :filename, :string
    field :extension, :string
    field :additions, :integer
    field :deletions, :integer
    field :patch, :string
    field :status, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :commit, Devhub.Integrations.GitHub.Commit

    timestamps()
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [
      :filename,
      :extension,
      :additions,
      :deletions,
      :patch,
      :status,
      :organization_id,
      :commit_id
    ])
    |> validate_required([
      :filename,
      :extension,
      :additions,
      :deletions,
      :status,
      :organization_id,
      :commit_id
    ])
    |> unique_constraint([:commit_id, :filename])
  end
end
