defmodule Devhub.Integrations.Linear.Actions.Projects do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.Linear.Project
  alias Devhub.Repo

  @callback projects(String.t()) :: [Project.t()]
  def projects(organization_id) do
    query =
      from p in Project,
        where: p.organization_id == ^organization_id

    Repo.all(query)
  end
end
