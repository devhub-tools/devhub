defmodule Devhub.Users.Actions.GetBy do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Users.User

  @callback get_by(Keyword.t()) :: {:ok, User.t()} | {:error, :user_not_found}
  def get_by(by) do
    query =
      from u in User,
        where: ^by,
        join: ou in assoc(u, :organization_users),
        on: is_nil(ou.archived_at),
        preload: [organization_users: {ou, [:roles]}]

    case Repo.one(query) do
      user when is_struct(user) -> {:ok, user}
      _error -> {:error, :user_not_found}
    end
  end
end
