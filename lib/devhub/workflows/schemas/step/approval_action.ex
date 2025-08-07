defmodule Devhub.Workflows.Schemas.Step.ApprovalAction do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(action, opts) do
      type = PolymorphicEmbed.get_polymorphic_type(Devhub.Workflows.Schemas.Step, :action, action)

      fields =
        action
        |> Map.take([:reviews_required])
        |> Map.put(:__type__, type)

      Jason.Encode.map(fields, opts)
    end
  end

  @primary_key false

  embedded_schema do
    field :reviews_required, :integer, default: 1
  end

  def changeset(action, params) do
    cast(action, params, [:reviews_required])
  end
end
