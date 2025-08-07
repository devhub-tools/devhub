defmodule Devhub.Integrations.Linear.Actions.UpsertLabel do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Linear.Label
  alias Devhub.Integrations.Linear.Team
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback upsert_label(Integration.t(), map()) :: {:ok, Label.t()} | {:error, Changeset.t()}
  def upsert_label(integration, label) do
    %{
      organization_id: integration.organization_id,
      external_id: label["id"],
      name: label["name"],
      color: label["color"],
      is_group: label["isGroup"],
      parent_label: maybe_get_parent_label(label),
      team: maybe_get_team(label)
    }
    |> Label.changeset()
    |> Repo.insert(
      on_conflict: {:replace, [:name, :color, :is_group, :parent_label_id, :team_id]},
      conflict_target: [:organization_id, :external_id],
      returning: true
    )
  end

  defp maybe_get_team(%{"team" => %{"id" => team_id}}) do
    Repo.get_by(Team, external_id: team_id)
  end

  defp maybe_get_team(%{"teamId" => team_id}) do
    Repo.get_by(Team, external_id: team_id)
  end

  defp maybe_get_team(_label), do: nil

  defp maybe_get_parent_label(%{"parent" => %{"id" => parent_label_id}}) do
    Repo.get_by(Label, external_id: parent_label_id)
  end

  defp maybe_get_parent_label(%{"parentId" => parent_label_id}) do
    Repo.get_by(Label, external_id: parent_label_id)
  end

  defp maybe_get_parent_label(_label), do: nil
end
