defmodule Devhub.Actions.Search do
  @moduledoc false

  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Dashboards.Schemas.Dashboard
  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.QueryDesk.Schemas.DatabaseColumn
  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Workspace
  alias Devhub.Users.Schemas.OrganizationUser
  alias Devhub.Workflows.Schemas.Workflow

  @callback search(OrganizationUser.t(), String.t(), Keyword.t()) :: [map()]
  def search(organization_user, search, opts) do
    super_admin? = organization_user.permissions.super_admin

    databases =
      from d in Database,
        left_join: p in assoc(d, :permissions),
        left_join: r in assoc(p, :role),
        left_join: rou in assoc(r, :organization_users),
        where: d.organization_id == ^organization_user.organization_id,
        where:
          ^super_admin? or not d.restrict_access or
            p.organization_user_id == ^organization_user.id or rou.id == ^organization_user.id,
        select: %{
          id: d.id,
          type: "Database",
          icon: "devhub-querydesk",
          title: d.name,
          subtitle: fragment("? || ' (' || ? || ')'", d.database, d.adapter),
          search: fragment("concat_ws(' ', ?, ?, ?)", d.database, d.group, d.name),
          group: d.group,
          link: fragment("'/querydesk/databases/' || ? || '/query'", d.id)
        },
        distinct: true

    dashboards =
      from d in Dashboard,
        left_join: p in assoc(d, :permissions),
        left_join: r in assoc(p, :role),
        left_join: rou in assoc(r, :organization_users),
        where: d.organization_id == ^organization_user.organization_id,
        where:
          ^super_admin? or not d.restricted_access or
            p.organization_user_id == ^organization_user.id or rou.id == ^organization_user.id,
        select: %{
          id: d.id,
          type: "Dashboard",
          icon: "hero-chart-bar",
          title: d.name,
          subtitle: nil,
          search: d.name,
          group: nil,
          link: fragment("'/dashboards/' || ? || '/view'", d.id)
        },
        distinct: true

    workflows =
      from w in Workflow,
        where: w.organization_id == ^organization_user.organization_id,
        select: %{
          id: w.id,
          type: "Workflow",
          icon: "hero-arrow-path-rounded-square",
          title: w.name,
          subtitle: nil,
          search: w.name,
          group: nil,
          link: fragment("'/workflows/' || ?", w.id)
        },
        distinct: true

    workspaces =
      from w in Workspace,
        where: w.organization_id == ^organization_user.organization_id,
        join: r in assoc(w, :repository),
        select: %{
          id: w.id,
          type: "Terraform Workspace",
          icon: "devhub-terradesk",
          title: w.name,
          subtitle: fragment("? || '/' || ?", r.owner, r.name),
          search: w.name,
          group: nil,
          link: fragment("'/terradesk/workspaces/' || ?", w.id)
        },
        distinct: true

    resources_query =
      databases
      |> union_all(^dashboards)
      |> union_all(^workflows)
      |> union_all(^workspaces)

    # add tables if on query view
    resources_query =
      case opts[:database_id] do
        database_id when is_binary(database_id) ->
          tables =
            from c in DatabaseColumn,
              join: d in assoc(c, :database),
              where: c.organization_id == ^organization_user.organization_id,
              where: c.database_id == ^opts[:database_id],
              select: %{
                id: c.table,
                type: "Table",
                icon: "devhub-querydesk",
                title: c.table,
                subtitle: nil,
                search: c.table,
                group: nil,
                link: fragment("'/querydesk/databases/' || ? || '/table/' || ?", c.database_id, c.table)
              },
              distinct: true

          union_all(resources_query, ^tables)

        _not_set ->
          resources_query
      end

    query =
      from cte in "combined",
        select: %{
          id: cte.id,
          type: cte.type,
          title: cte.title,
          subtitle: cte.subtitle,
          icon: cte.icon,
          group: cte.group,
          link: cte.link
        },
        order_by: {:desc, fragment("word_similarity(?, ?)", cte.search, ^search)},
        where: fragment("word_similarity(?, ?) > 0", cte.search, ^search)

    query
    |> with_cte("combined", as: ^resources_query)
    |> Repo.all()
  end
end
