defmodule Devhub.Coverbot.TestReports.Schemas.TestSuite do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Coverbot.TestReports.Schemas.TestSuiteRun
  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Users.Schemas.Organization

  @type t :: %__MODULE__{
          name: String.t(),
          test_suite_runs: [TestSuiteRun.t()],
          organization: Organization.t(),
          repository: Repository.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "test_suite"}
  schema "test_suites" do
    field :name, :string
    has_many :test_suite_runs, TestSuiteRun, preload_order: [desc: :inserted_at]
    belongs_to :organization, Organization
    belongs_to :repository, Repository

    timestamps()
  end

  def changeset(test_suite \\ %__MODULE__{}, params) do
    test_suite
    |> cast(params, [
      :name,
      :organization_id,
      :repository_id
    ])
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:repository_id)
  end
end
