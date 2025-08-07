defmodule Devhub.Workflows.Schemas.Step.SlackReplyAction do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(action, opts) do
      type = PolymorphicEmbed.get_polymorphic_type(Devhub.Workflows.Schemas.Step, :action, action)

      fields =
        action
        |> Map.take([:reply_to_step_name, :message])
        |> Map.put(:__type__, type)

      Jason.Encode.map(fields, opts)
    end
  end

  @primary_key false

  embedded_schema do
    field :reply_to_step_name, :string
    field :message, :string
  end

  def changeset(action, params) do
    cast(action, params, [:reply_to_step_name, :message])
  end
end
