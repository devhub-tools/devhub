defmodule Devhub.Integrations.Actions.GetTasks do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.Integrations.Linear.Issue
  alias Devhub.Repo

  @callback get_tasks(Keyword.t(), Keyword.t()) :: [Issue.t()]
  def get_tasks(filter, opts) do
    # TODO: this will need to be refactored when we have more than one integration
    query =
      from i in Issue,
        limit: ^(opts[:limit] || 10)

    query
    |> query_filter(filter)
    |> Repo.all()
  end
end
