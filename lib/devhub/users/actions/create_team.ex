defmodule Devhub.Users.Actions.CreateTeam do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.Team

  @callback create_team(String.t(), Organization.t()) ::
              {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  def create_team(name, organization) do
    %Team{}
    |> Team.changeset(%{name: name, organization_id: organization.id})
    |> Repo.insert()
  end
end
