defmodule Devhub.Users.Actions.RegisterPasskey do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.Schemas.Passkey
  alias Devhub.Users.User

  @callback register_passkey(User.t(), map()) :: {:ok, Passkey.t()} | {:error, Ecto.Changeset.t()}
  def register_passkey(user, params) do
    params
    |> Map.put(:user_id, user.id)
    |> Passkey.changeset()
    |> Repo.insert()
  end
end
