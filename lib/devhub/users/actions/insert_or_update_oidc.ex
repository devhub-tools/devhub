defmodule Devhub.Users.Actions.InsertOrUpdateOidc do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.OIDC

  @callback insert_or_update_oidc(OIDC.t(), map()) :: {:ok, OIDC.t()} | {:error, Ecto.Changeset.t()}
  def insert_or_update_oidc(oidc, attrs) do
    oidc
    |> OIDC.changeset(attrs)
    |> Repo.insert_or_update()
  end
end
