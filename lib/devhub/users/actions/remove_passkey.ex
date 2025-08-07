defmodule Devhub.Users.Actions.RemovePasskey do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.Schemas.Passkey
  alias Devhub.Users.User

  @callback remove_passkey(User.t(), Passkey.t()) ::
              {:ok, Passkey.t()} | {:error, Ecto.Changeset.t()} | {:error, :user_id_mismatch}
  def remove_passkey(user, passkey) do
    if user.id == passkey.user_id do
      Repo.delete(passkey)
    else
      {:error, :user_id_mismatch}
    end
  end
end
