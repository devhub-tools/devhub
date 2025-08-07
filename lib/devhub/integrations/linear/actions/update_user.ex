defmodule Devhub.Integrations.Linear.Actions.UpdateUser do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Linear.User
  alias Devhub.Repo

  @callback update_user(User.t(), map()) :: {:ok, User.t()}
  def update_user(user, params) do
    user
    |> User.changeset(params)
    |> Repo.update()
  end
end
