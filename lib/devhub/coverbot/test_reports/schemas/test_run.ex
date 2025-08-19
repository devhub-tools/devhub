defmodule Devhub.Coverbot.TestReports.Schemas.TestRun do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Coverbot.TestReports.Schemas.TestSuiteRun

  @type status :: :passed | :failed | :skipped | :errored

  @type t :: %__MODULE__{
          class_name: String.t(),
          file_name: String.t(),
          test_name: String.t(),
          execution_time_seconds: Decimal.t(),
          info: map() | nil,
          status: status(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "test_run"}
  schema "test_runs" do
    field :class_name, :string
    field :file_name, :string
    field :test_name, :string
    field :execution_time_seconds, :decimal
    field :status, Ecto.Enum, values: [:passed, :failed, :skipped, :errored]

    embeds_one :info, Info, primary_key: false do
      field :message, :string
      field :stacktrace, :string
    end

    belongs_to :test_suite_run, TestSuiteRun

    timestamps()
  end

  def changeset(test_run \\ %__MODULE__{}, params) do
    test_run
    |> cast(params, [:class_name, :file_name, :test_name, :execution_time_seconds, :status])
    |> cast_embed(:info, with: &info_changeset/2)
    |> validate_required([:class_name, :file_name, :test_name, :execution_time_seconds, :status])
  end

  defp info_changeset(info, attrs) do
    cast(info, attrs, [:message, :stacktrace])
  end
end
