defmodule Devhub.Users.Actions.GetPasskeys do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Users.Schemas.Passkey
  alias Devhub.Users.User

  @callback get_passkeys(User.t()) :: [Passkey.t()]
  def get_passkeys(%User{} = user) do
    get_passkeys(user.id)
  end

  def get_passkeys(user_id) do
    query =
      from p in Passkey,
        where: p.user_id == ^user_id,
        order_by: p.inserted_at

    Repo.all(query)
  end
end
