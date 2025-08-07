defmodule Devhub.Coverbot.Actions.CoverageData do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Coverbot.Coverage
  alias Devhub.Repo

  @callback coverage_data(String.t()) :: [%{date: Date.t(), percentage: float()}]
  def coverage_data(repository_id) do
    query =
      from c in Coverage,
        select: %{
          date: fragment("date_trunc('week', ?)", c.inserted_at),
          percentage: type(fragment("ROUND(AVG(?), 2)", c.percentage), :float)
        },
        where: c.repository_id == ^repository_id and c.is_for_default_branch,
        limit: 52,
        order_by: {:desc, 1},
        group_by: 1

    query |> Repo.all() |> Enum.reverse()
  end
end
