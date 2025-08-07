defmodule Devhub.Workflows.Schemas.Step.SlackAction do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(action, opts) do
      type = PolymorphicEmbed.get_polymorphic_type(Devhub.Workflows.Schemas.Step, :action, action)

      fields =
        action
        |> Map.take([:slack_channel, :message, :link_text])
        |> Map.put(:__type__, type)

      Jason.Encode.map(fields, opts)
    end
  end

  @primary_key false

  embedded_schema do
    field :slack_channel, :string
    field :message, :string
    field :link_text, :string
  end

  def changeset(action, params) do
    cast(action, params, [:slack_channel, :message, :link_text])
  end
end
