defmodule Devhub.Coverbot.TestReports.Actions.GetTestSuiteRunTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "success" do
    organization = insert(:organization)
    repository = insert(:repository, organization_id: organization.id)
    test_suite = insert(:test_suite, name: "devhub_elixir", organization: organization, repository: repository)

    %{id: test_suite_run_id, commit_id: commit_id} =
      insert(:test_suite_run, organization: organization, test_suite: test_suite, repository: repository)

    assert {:ok, %{id: ^test_suite_run_id}} = Coverbot.get_test_suite_run(id: test_suite_run_id)

    assert {:ok, %{id: ^test_suite_run_id}} =
             Coverbot.get_test_suite_run(test_suite_id: test_suite.id, commit_id: commit_id)
  end

  test "not found" do
    assert {:error, :test_suite_run_not_found} = Coverbot.get_test_suite_run(id: "not-found")
  end
end
