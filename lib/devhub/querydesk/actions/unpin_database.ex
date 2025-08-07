defmodule Devhub.QueryDesk.Actions.UnpinDatabase do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.UserPinnedDatabase
  alias Devhub.Repo

  @callback unpin_database(UserPinnedDatabase.t()) ::
              {:ok, UserPinnedDatabase.t()} | {:error, Ecto.Changeset.t()}
  def unpin_database(user_pinned_database) do
    Repo.delete(user_pinned_database)
  end
end
