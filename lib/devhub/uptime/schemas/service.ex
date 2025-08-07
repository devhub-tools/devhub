defmodule Devhub.Uptime.Schemas.Service do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Uptime.Schemas.Check
  alias DevhubProtos.RequestTracer.V1.TraceResponse

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          method: String.t(),
          url: String.t(),
          expected_status_code: String.t(),
          expected_response_body: String.t(),
          interval_ms: integer(),
          timeout_ms: integer(),
          checks: [Check.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "svc"}
  schema "uptime_services" do
    field :name, :string
    field :method, :string, default: "GET"
    field :url, :string
    field :request_body, :string
    # expected status code is a string as it can also be a pattern like "2xx"
    field :expected_status_code, :string, default: "2xx"
    field :expected_response_body, :string
    field :interval_ms, :integer, default: 60_000
    field :timeout_ms, :integer, default: 10_000
    field :enabled, :boolean, default: true

    embeds_many :request_headers, RequestHeader, primary_key: false, on_replace: :delete do
      field :key, :string
      field :value, :string
    end

    belongs_to :organization, Devhub.Users.Schemas.Organization
    has_many :checks, Check, preload_order: [desc: :inserted_at]

    timestamps()
  end

  def changeset(model \\ %__MODULE__{}, attrs) do
    model
    |> cast(attrs, [
      :organization_id,
      :name,
      :method,
      :url,
      :request_body,
      :expected_status_code,
      :expected_response_body,
      :interval_ms,
      :timeout_ms,
      :enabled
    ])
    |> cast_embed(:request_headers,
      with: &header_changeset/2,
      sort_param: :header_sort,
      drop_param: :header_drop
    )
    |> validate_required([:name, :url])
    |> unique_constraint(:name)
    |> validate_timeout_interval()
    |> validate_interval()
  end

  def header_changeset(header, attrs \\ %{}) do
    header
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
  end

  defp validate_timeout_interval(%Ecto.Changeset{} = changeset) do
    timeout_ms = get_field(changeset, :timeout_ms)
    interval_ms = get_field(changeset, :interval_ms)

    if timeout_ms >= interval_ms do
      add_error(changeset, :timeout_ms, "must be smaller than interval")
    else
      changeset
    end
  end

  defp validate_interval(%Ecto.Changeset{} = changeset) do
    if Devhub.cloud_hosted?() do
      validate_number(changeset, :interval_ms, greater_than: 60_000, message: "must be at least 60 seconds")
    else
      changeset
    end
  end

  # TODO: logic is WIP
  @spec status(__MODULE__.t(), TraceResponse.t()) :: Check.status()
  def status(%__MODULE__{} = service, %TraceResponse{} = result) do
    result =
      with :error <- Integer.parse(service.expected_status_code),
           :error <- regex?(service.expected_response_body, result.response_body),
           true <- service.expected_response_body == "" do
        :failure
      else
        {parsed_expected_code, _str} when is_integer(parsed_expected_code) ->
          status_code?(parsed_expected_code, result.status_code)

        {:ok, result} when is_boolean(result) ->
          result

        false ->
          response_body?(service.expected_response_body, result.response_body)
      end

    if result do
      :success
    else
      :failure
    end
  end

  @spec status_code?(integer(), integer()) :: boolean()
  defp status_code?(_expected_parsed_code, nil), do: false

  @spec status_code?(integer(), integer()) :: boolean()
  defp status_code?(expected_parsed_code, status_code_result) do
    expected_code_length = expected_parsed_code |> Integer.digits() |> length()

    cond do
      expected_code_length == 3 ->
        expected_parsed_code == status_code_result

      expected_code_length == 1 ->
        status_code_result |> Integer.digits() |> Enum.at(0) == expected_parsed_code

      true ->
        false
    end
  end

  @spec regex?(String.t(), String.t()) :: boolean()
  defp regex?(expected, value) do
    case Regex.compile(expected) do
      {:ok, regex} ->
        {:ok, Regex.match?(regex, value)}

      {:error, _error} ->
        :error
    end
  end

  @spec response_body?(String.t(), String.t()) :: boolean()
  defp response_body?(expected, value) do
    String.contains?(value, expected)
  end
end
