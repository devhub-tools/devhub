defmodule Devhub.Integrations.Linear.Actions.Users do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.Linear.User
  alias Devhub.Repo

  @callback users(String.t()) :: [User.t()]
  @callback users(String.t(), String.t() | nil) :: [User.t()]
  def users(organization_id, team_id \\ nil) do
    query =
      from lu in User,
        left_join: ou in assoc(lu, :organization_user),
        where: lu.organization_id == ^organization_id,
        where: is_nil(ou.archived_at),
        select: [:id, :name],
        preload: [organization_user: ou]

    query =
      if team_id do
        from [lu, ou] in query,
          join: tm in assoc(ou, :team_members),
          where: tm.team_id == ^team_id,
          preload: [organization_user: ou]
      else
        query
      end

    Repo.all(query)
  end
end
