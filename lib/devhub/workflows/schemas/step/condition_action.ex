defmodule Devhub.Workflows.Schemas.Step.ConditionAction do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(action, opts) do
      type = PolymorphicEmbed.get_polymorphic_type(Devhub.Workflows.Schemas.Step, :action, action)

      fields =
        action
        |> Map.take([:condition, :when_false])
        |> Map.put(:__type__, type)

      Jason.Encode.map(fields, opts)
    end
  end

  @primary_key false

  embedded_schema do
    field :condition, :string
    field :when_false, Ecto.Enum, values: [:succeeded, :failed], default: :failed
  end

  def changeset(action, params) do
    cast(action, params, [:condition, :when_false])
  end
end
