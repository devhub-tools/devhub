defmodule Devhub.Integrations.Linear.Actions.UpdateLabel do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Linear.Label
  alias Devhub.Repo

  @callback update_label(Label.t(), map()) :: {:ok, Label.t()} | {:error, Changeset.t()}
  def update_label(label, params) do
    label
    |> Label.form_changeset(params)
    |> Repo.update()
  end
end
