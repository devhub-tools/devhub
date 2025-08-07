defmodule Devhub.Integrations.Linear.Actions.GetLabel do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Linear.Label
  alias Devhub.Repo

  @callback get_label(Keyword.t()) :: {:ok, Label.t()} | {:error, :label_not_found}
  def get_label(by) do
    case Repo.get_by(Label, by) do
      %Label{} = label -> {:ok, label}
      nil -> {:error, :label_not_found}
    end
  end
end
