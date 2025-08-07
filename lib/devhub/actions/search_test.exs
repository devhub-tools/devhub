defmodule Devhub.Actions.SearchTest do
  use Devhub.DataCase, async: true

  test "search/3" do
    organization = insert(:organization)
    organization_user = insert(:organization_user, organization: organization)
    database = insert(:database, organization: organization, name: "devhub")
    database_column = insert(:database_column, database: database, organization: organization, table: "users", name: "id")

    dashboard = insert(:dashboard, organization: organization, name: "devhub")
    workflow = insert(:workflow, organization: organization, name: "devhub")

    repository = insert(:repository, organization: organization)
    workspace = insert(:workspace, organization: organization, name: "devhub", repository: repository)

    assert [
             %{
               id: dashboard.id,
               type: "Dashboard",
               link: "/dashboards/#{dashboard.id}/view",
               group: nil,
               title: "devhub",
               icon: "hero-chart-bar",
               subtitle: nil
             },
             %{
               id: workflow.id,
               type: "Workflow",
               link: "/workflows/#{workflow.id}",
               group: nil,
               title: "devhub",
               icon: "hero-arrow-path-rounded-square",
               subtitle: nil
             },
             %{
               id: workspace.id,
               type: "Terraform Workspace",
               link: "/terradesk/workspaces/#{workspace.id}",
               group: nil,
               title: "devhub",
               icon: "devhub-terradesk",
               subtitle: "#{repository.owner}/#{repository.name}"
             },
             %{
               id: database.id,
               type: "Database",
               link: "/querydesk/databases/#{database.id}/query",
               group: nil,
               title: "devhub",
               icon: "devhub-querydesk",
               subtitle: "devhub_test (postgres)"
             }
           ] == Devhub.search(organization_user, "devhub")

    assert [
             %{
               id: "users",
               type: "Table",
               link: "/querydesk/databases/#{database.id}/table/#{database_column.table}",
               group: nil,
               title: "users",
               icon: "devhub-querydesk",
               subtitle: nil
             }
           ] == Devhub.search(organization_user, "users", database_id: database.id)
  end
end
