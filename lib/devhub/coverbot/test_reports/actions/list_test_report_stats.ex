defmodule Devhub.Coverbot.TestReports.Actions.ListTestReportStats do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Coverbot.TestReports.Schemas.TestSuite
  alias Devhub.Coverbot.TestReports.Schemas.TestSuiteRun
  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization

  @callback list_test_report_stats(Organization.t()) :: [map()]
  def list_test_report_stats(organization) do
    last_test_suite_run =
      from tsr in TestSuiteRun,
        distinct: tsr.test_suite_id,
        order_by: [desc: :inserted_at]

    query =
      from ts in TestSuite,
        where: ts.organization_id == ^organization.id,
        inner_join: ltsr in subquery(last_test_suite_run),
        on: ltsr.test_suite_id == ts.id,
        join: repository in assoc(ts, :repository),
        preload: [:repository],
        select: %{
          test_suite: ts,
          last_test_suite_run: ltsr
        },
        order_by: [desc: ltsr.inserted_at]

    Repo.all(query)
  end
end
