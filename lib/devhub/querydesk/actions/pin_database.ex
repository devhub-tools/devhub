defmodule Devhub.QueryDesk.Actions.PinDatabase do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.QueryDesk.Schemas.UserPinnedDatabase
  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser

  @callback pin_database(OrganizationUser.t(), Database.t()) ::
              {:ok, UserPinnedDatabase.t()} | {:error, Ecto.Changeset.t()}
  def pin_database(organization_user, database) do
    %{database_id: database.id, organization_user_id: organization_user.id}
    |> UserPinnedDatabase.changeset()
    |> Repo.insert()
  end
end
