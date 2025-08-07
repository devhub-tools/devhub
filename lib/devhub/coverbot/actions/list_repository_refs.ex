defmodule Devhub.Coverbot.Actions.ListRepositoryRefs do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Coverbot.Coverage
  alias Devhub.Repo

  @callback list_repository_refs(Keyword.t()) :: [Coverage.t()]
  def list_repository_refs(by) do
    query =
      from c in Coverage,
        select: %{id: max(c.id)},
        where: ^by,
        group_by: [:repository_id, :ref],
        order_by: [desc: max(c.id)],
        limit: 20

    ids = query |> Repo.all() |> Enum.map(& &1.id)

    query =
      from c in Coverage,
        where: c.id in ^ids,
        order_by: [desc: c.updated_at]

    Repo.all(query)
  end
end
