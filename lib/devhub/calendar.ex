defmodule Devhub.Calendar do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Calendar.Client
  alias Devhub.Calendar.Deserialize
  alias Devhub.Calendar.Storage
  alias Devhub.Integrations.Schemas.Ical
  alias Devhub.Users.Schemas.Organization

  require Logger

  @callback get_events(Organization.t(), Date.t(), Date.t()) :: [Event.t()]
  def get_events(organization, start_date, end_date) do
    Storage.get_events(organization, start_date, end_date)
  end

  @callback create_event(map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def create_event(params) do
    Storage.create_event(params)
  end

  @callback sync(Ical.t()) :: :ok
  def sync(integration) do
    Logger.info("Syncing calendar for integration: #{integration.id}")

    {:ok, %{body: body}} = Client.ical(integration.link)

    body
    |> Deserialize.from_ics()
    |> Enum.map(fn event ->
      event
      |> Map.put(:organization_id, integration.organization_id)
      |> Map.put(:id, UXID.generate!(prefix: "evt"))
      |> Map.put(:title, integration.title)
      |> Map.put(:color, integration.color)
    end)
    |> Storage.insert_events()

    :ok
  end

  # TODO: make this configurable per organization
  @callback count_business_days(Date.t(), Date.t()) :: non_neg_integer()
  def count_business_days(start_date, end_date) do
    start_date
    |> Date.range(end_date)
    |> Enum.count(fn date ->
      case Date.day_of_week(date) do
        # Friday
        5 -> false
        # Saturday
        6 -> false
        # Sunday
        7 -> false
        # Weekday
        _other -> true
      end
    end)
  end
end
