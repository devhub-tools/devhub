defmodule Devhub.QueryDesk.Actions.ListDatabases do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser

  @callback list_databases(OrganizationUser.t()) :: %{required(String.t() | nil) => [Database.t()]}
  @callback list_databases(OrganizationUser.t(), Keyword.t()) :: %{required(String.t() | nil) => [Database.t()]}
  def list_databases(organization_user, opts \\ []) do
    super_admin? = organization_user.permissions.super_admin

    query =
      from d in Database,
        left_join: p in assoc(d, :permissions),
        left_join: r in assoc(p, :role),
        left_join: rou in assoc(r, :organization_users),
        left_join: upd in assoc(d, :user_pins),
        as: :user_pins,
        on: upd.organization_user_id == ^organization_user.id,
        where: d.organization_id == ^organization_user.organization_id,
        where:
          d.restrict_access == false or ^super_admin? or p.organization_user_id == ^organization_user.id or
            rou.id == ^organization_user.id,
        order_by: fragment("lower(?)", d.name),
        preload: [user_pins: upd]

    query
    |> maybe_filter(opts[:filter])
    |> Repo.all()
  end

  defp maybe_filter(query, :favorites) do
    from [user_pins: upd] in query, where: not is_nil(upd.id)
  end

  defp maybe_filter(query, by) when is_list(by) do
    from d in query, where: ^by
  end

  defp maybe_filter(query, nil), do: query
end
