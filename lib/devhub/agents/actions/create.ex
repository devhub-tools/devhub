defmodule Devhub.Agents.Actions.Create do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Agents.Schemas.Agent
  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization

  @callback create(String.t(), Organization.t()) :: {:ok, Agent.t()} | {:error, Ecto.Changeset.t()}
  def create(name, organization) do
    %{name: name, organization_id: organization.id}
    |> Agent.create_changeset()
    |> Repo.insert()
  end
end
