defmodule Devhub.TerraDesk.Actions.ListSchedules do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Schedule

  @callback list_schedules(Keyword.t()) :: [Schedule.t()]
  def list_schedules(opts) do
    query =
      from s in Schedule,
        order_by: [asc: s.name]

    query
    |> query_filter(opts[:filter] || [])
    |> Repo.all()
  end
end
