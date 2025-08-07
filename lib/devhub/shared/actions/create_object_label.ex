defmodule Devhub.Shared.Actions.CreateObjectLabel do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Shared.Schemas.LabeledObject

  @callback create_object_label(map()) :: {:ok, LabeledObject.t()} | {:error, Ecto.Changeset.t()}
  def create_object_label(params) do
    params
    |> LabeledObject.create_changeset()
    |> Repo.insert()
  end
end
