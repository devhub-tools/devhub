defmodule Devhub.Calendar.Client do
  @moduledoc false
  use Tesla

  plug Tesla.Middleware.OpenTelemetry
  plug Tesla.Middleware.JSON

  def ical("webcal" <> link) do
    get("https" <> link)
  end
end
