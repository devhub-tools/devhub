defmodule Devhub.Workflows.Schemas.Step.ApiAction do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(action, opts) do
      type = PolymorphicEmbed.get_polymorphic_type(Devhub.Workflows.Schemas.Step, :action, action)

      fields =
        action
        |> Map.take([:endpoint, :method, :headers, :body, :expected_status_code, :include_devhub_jwt])
        |> Map.put(:__type__, type)
        |> Map.put(:method, String.upcase(to_string(action.method)))

      Jason.Encode.map(fields, opts)
    end
  end

  @primary_key false

  embedded_schema do
    field :endpoint, :string
    field :method, Ecto.Enum, values: [:get, :post, :put, :patch, :delete], default: :get

    embeds_many :headers, Header, primary_key: false, on_replace: :delete do
      @derive Jason.Encoder

      field :key, :string
      field :value, Devhub.Types.EncryptedEmbed, redact: true
    end

    field :body, :string
    field :expected_status_code, :integer, default: 200
    field :include_devhub_jwt, :boolean, default: false
  end

  def changeset(action, params) do
    params =
      params
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put("method", String.downcase(params["method"] || "get"))

    action
    |> cast(params, [:endpoint, :method, :body, :expected_status_code, :include_devhub_jwt])
    |> cast_embed(:headers,
      with: &header_changeset/2,
      sort_param: :header_sort,
      drop_param: :header_drop
    )
  end

  def header_changeset(header, attrs \\ %{}) do
    attrs =
      if is_struct(attrs) do
        Map.from_struct(attrs)
      else
        attrs
      end

    cast(header, attrs, [:key, :value])
  end

  def format_result(%{"body" => body}) do
    Jason.Formatter.pretty_print(body)
  end

  def format_result(%{"error" => error}) do
    error
  end

  def format_result(_output) do
    ""
  end
end
