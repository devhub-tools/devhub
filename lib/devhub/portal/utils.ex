defmodule Devhub.Metrics.Utils do
  @moduledoc false
  use DevhubWeb, :live_view

  def params_to_assigns(socket, params) do
    start_date = start_date_from_params(params)
    end_date = end_date_from_params(socket.assigns.user.timezone, params)
    team = Enum.find(socket.assigns.teams, fn team -> team.id == params["team_id"] end)

    assign(
      socket,
      start_date: start_date,
      end_date: end_date,
      selected_team_id: team.id,
      selected_team_name: team.name
    )
  end
end
