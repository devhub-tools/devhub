defmodule Devhub.Coverbot.Coverage do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Users.Schemas.Organization

  @type t :: %__MODULE__{
          is_for_default_branch: boolean(),
          sha: String.t(),
          ref: String.t(),
          covered: integer(),
          relevant: integer(),
          percentage: Decimal.t(),
          files: map() | nil
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "cov"}
  schema "coverage" do
    field :is_for_default_branch, :boolean
    field :sha, :string
    field :ref, :string
    field :covered, :integer
    field :relevant, :integer
    field :percentage, :decimal
    field :files, :map

    belongs_to :organization, Organization
    belongs_to :repository, Repository

    timestamps()
  end

  def changeset(coverage \\ %__MODULE__{}, params) do
    coverage
    |> cast(params, [
      :is_for_default_branch,
      :sha,
      :ref,
      :covered,
      :relevant,
      :percentage,
      :organization_id,
      :repository_id,
      :files
    ])
    |> validate_required([
      :is_for_default_branch,
      :sha,
      :ref,
      :covered,
      :relevant,
      :percentage,
      :organization_id,
      :repository_id
    ])
    |> unique_constraint([:sha, :repository_id])
  end
end
