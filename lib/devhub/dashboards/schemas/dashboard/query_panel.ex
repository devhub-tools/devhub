defmodule Devhub.Dashboards.Schemas.Dashboard.QueryPanel do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.DatabaseCredential

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(panel, opts) do
      type = PolymorphicEmbed.get_polymorphic_type(Devhub.Dashboards.Schemas.Dashboard.Panel, :details, panel)

      fields =
        panel
        |> Map.take([:query, :credential_id])
        |> Map.put(:__type__, type)

      Jason.Encode.map(fields, opts)
    end
  end

  @primary_key false

  embedded_schema do
    field :query, :string
    field :credential_search, :string, virtual: true

    belongs_to :credential, DatabaseCredential
  end

  def changeset(panel, params) do
    cast(panel, params, [:query, :credential_id, :credential_search])
  end
end
