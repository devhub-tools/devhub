defmodule Devhub.Workflows.Schemas.Step.QueryAction do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.DatabaseCredential

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(action, opts) do
      type = PolymorphicEmbed.get_polymorphic_type(Devhub.Workflows.Schemas.Step, :action, action)

      fields =
        action
        |> Map.take([:query, :timeout, :credential_id])
        |> Map.put(:__type__, type)

      Jason.Encode.map(fields, opts)
    end
  end

  @primary_key false

  embedded_schema do
    field :query, :string
    field :timeout, :integer, default: 5
    field :credential_search, :string, virtual: true

    belongs_to :credential, DatabaseCredential
  end

  def changeset(action, params) do
    cast(action, params, [:query, :timeout, :credential_id, :credential_search])
  end

  def format_result(%Postgrex.Result{} = result) do
    result = Map.from_struct(result)
    rows = result.rows && Enum.map(result.rows, fn row -> Enum.map(row, &format_field/1) end)
    Map.new(%{result | rows: rows}, fn {k, v} -> {to_string(k), v} end)
  end

  def format_result(result) when is_list(result), do: %{results: result}

  defp format_field(field) when is_binary(field) do
    with :error <- if(String.printable?(field), do: {:ok, field}, else: :error),
         :error <- Ecto.UUID.cast(field) do
      "BINARY (#{byte_size(field)} bytes)"
    else
      {:ok, field} -> field
    end
  end

  defp format_field(field), do: field
end
