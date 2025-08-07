defmodule Devhub.Uptime.Schemas.Check do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type status :: :pending | :success | :failure | :timeout

  @type t :: %__MODULE__{
          id: String.t(),
          status: status(),
          status_code: integer(),
          response_body: binary(),
          dns_time: integer(),
          connect_time: integer(),
          tls_time: integer(),
          first_byte_time: integer(),
          request_time: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "chk"}
  schema "uptime_checks" do
    field :status, Ecto.Enum, values: [:pending, :success, :failure, :timeout]
    field :status_code, :integer
    field :response_body, :binary
    field :dns_time, :integer
    field :connect_time, :integer
    field :tls_time, :integer
    field :first_byte_time, :integer
    field :request_time, :integer
    field :time_since_last_check, :integer

    embeds_many :response_headers, ResponseHeader, primary_key: false do
      field :key, :string
      field :value, :string
    end

    belongs_to :service, Devhub.Uptime.Schemas.Service
    belongs_to :organization, Devhub.Users.Schemas.Organization

    timestamps()
  end

  def changeset(model \\ %__MODULE__{}, attrs) do
    model
    |> cast(attrs, [
      :organization_id,
      :status,
      :status_code,
      :response_body,
      :dns_time,
      :connect_time,
      :tls_time,
      :first_byte_time,
      :request_time,
      :service_id,
      :time_since_last_check
    ])
    |> cast_embed(:response_headers, with: &header_changeset/2)
    |> validate_required([
      :status,
      :time_since_last_check
    ])
  end

  def header_changeset(header, attrs \\ %{}) do
    header
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
  end
end
