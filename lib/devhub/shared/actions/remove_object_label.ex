defmodule Devhub.Shared.Actions.RemoveObjectLabel do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Shared.Schemas.LabeledObject

  @callback remove_object_label(Keyword.t()) :: {non_neg_integer(), nil | [term()]}
  def remove_object_label(by) do
    query =
      from lo in LabeledObject,
        where: ^by

    Repo.delete_all(query)
  end
end
