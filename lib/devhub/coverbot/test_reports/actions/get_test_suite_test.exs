defmodule Devhub.Coverbot.TestReports.Actions.GetTestSuiteTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "get_test_suite/1" do
    %{id: organization_id} = organization = insert(:organization)
    repository = insert(:repository, organization_id: organization_id)
    %{id: test_suite_id} = insert(:test_suite, organization: organization, repository: repository)

    assert {:ok, %{id: ^test_suite_id}} = Coverbot.get_test_suite(test_suite_id)
    assert {:error, :test_suite_not_found} = Coverbot.get_test_suite("1234_fake_id")
  end
end
