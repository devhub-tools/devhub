defmodule Devhub.Shared.Actions.DeleteLabel do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Shared.Schemas.Label

  @callback delete_label(Label.t()) :: {:ok, Label.t()} | {:error, Ecto.Changeset.t()}
  def delete_label(label) do
    Repo.delete(label)
  end
end
