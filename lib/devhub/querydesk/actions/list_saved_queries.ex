defmodule Devhub.QueryDesk.Actions.ListSavedQueries do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser

  @callback list_saved_queries(OrganizationUser.t()) :: [SavedQuery.t()]
  @callback list_saved_queries(OrganizationUser.t(), Keyword.t()) :: [SavedQuery.t()]
  def list_saved_queries(organization_user, opts \\ []) do
    query =
      from sq in SavedQuery,
        where: not sq.private or sq.created_by_user_id == ^organization_user.user_id,
        left_join: l in assoc(sq, :labels),
        where: sq.organization_id == ^organization_user.organization_id,
        order_by: [desc: sq.updated_at],
        preload: [labels: l]

    query
    |> query_filter(opts[:filter] || [])
    |> Repo.all()
  end
end
