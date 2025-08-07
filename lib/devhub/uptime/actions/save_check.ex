defmodule Devhub.Uptime.Actions.SaveCheck do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Uptime.Actions.PubSub, only: [broadcast!: 1]

  alias Devhub.Repo
  alias Devhub.Uptime.Schemas.Check

  @callback save_check!(map()) :: Check.t()
  def save_check!(attrs) do
    attrs
    |> Check.changeset()
    |> Repo.insert!()
    |> tap(&broadcast!/1)
  end
end
