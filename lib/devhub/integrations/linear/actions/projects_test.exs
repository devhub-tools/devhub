defmodule Devhub.Integrations.Linear.Actions.ProjectsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear

  test "projects/1" do
    organization = insert(:organization)
    other_organization = insert(:organization)

    project_ids = 3 |> insert_list(:project, organization: organization) |> Enum.map(& &1.id)
    insert(:project, organization: other_organization)

    projects = Linear.projects(organization.id)
    assert length(projects) == 3
    assert Enum.all?(projects, &(&1.id in project_ids))
  end
end
