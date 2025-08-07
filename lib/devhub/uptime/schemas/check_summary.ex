defmodule Devhub.Uptime.Schemas.CheckSummary do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: String.t(),
          date: Date.t(),
          success_percentage: Decimal.t(),
          avg_dns_time: Decimal.t(),
          avg_connect_time: Decimal.t(),
          avg_tls_time: Decimal.t(),
          avg_first_byte_time: Decimal.t(),
          avg_to_finish: Decimal.t(),
          avg_request_time: Decimal.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "chk_sum"}
  schema "uptime_check_summaries" do
    field :date, :date
    field :success_percentage, :decimal
    field :avg_dns_time, :decimal
    field :avg_connect_time, :decimal
    field :avg_tls_time, :decimal
    field :avg_first_byte_time, :decimal
    field :avg_to_finish, :decimal
    field :avg_request_time, :decimal

    belongs_to :service, Devhub.Uptime.Schemas.Service
  end

  def changeset(model \\ %__MODULE__{}, attrs) do
    model
    |> cast(attrs, [
      :organization_id,
      :service_id,
      :date,
      :avg_response_body,
      :avg_dns_time,
      :avg_connect_time,
      :avg_tls_time,
      :avg_first_byte_time,
      :avg_to_finish,
      :avg_request_time
    ])
    |> validate_required([
      :organization_id,
      :service_id,
      :date,
      :avg_response_body,
      :avg_dns_time,
      :avg_connect_time,
      :avg_tls_time,
      :avg_first_byte_time,
      :avg_to_finish,
      :avg_request_time
    ])
  end
end
