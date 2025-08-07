defmodule Devhub.Calendar.Storage do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Calendar.Event
  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization

  @callback get_events(Organization.t(), Date.t(), Date.t()) :: [Event.t()]
  def get_events(organization, start_date, end_date) do
    query =
      from e in Event,
        left_join: lu in assoc(e, :linear_user),
        left_join: ou in assoc(lu, :organization_user),
        where: e.organization_id == ^organization.id,
        where: e.start_date <= ^end_date,
        where: e.end_date >= ^start_date,
        preload: [linear_user: {lu, [organization_user: ou]}]

    Repo.all(query)
  end

  @callback create_event(map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def create_event(params) do
    params
    |> Event.changeset()
    |> Repo.insert()
  end

  @callback insert_events([map()]) :: {non_neg_integer(), nil | [term()]}
  def insert_events(events) do
    Repo.insert_all(Event, events,
      conflict_target: [:organization_id, :external_id],
      on_conflict: {:replace, [:person, :start_date, :end_date, :title]},
      returning: true
    )
  end
end
