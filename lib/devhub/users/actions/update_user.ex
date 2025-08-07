defmodule Devhub.Users.Actions.UpdateUser do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.User

  @callback update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(user, params) do
    user
    |> User.changeset(params)
    |> Repo.update()
  end
end
