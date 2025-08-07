defmodule Devhub.QueryDesk.Schemas.Query do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.DatabaseCredential
  alias Devhub.QueryDesk.Schemas.QueryApproval
  alias Devhub.QueryDesk.Schemas.QueryComment
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.User

  @type t :: %__MODULE__{
          query: String.t(),
          failed: boolean(),
          is_system: boolean(),
          slack_channel: String.t() | nil,
          slack_message_ts: String.t() | nil,
          limit: integer(),
          timeout: integer(),
          run_on_approval: boolean(),
          executed_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {LiveSync.Watch, [subscription_key: :organization_id]}

  @primary_key {:id, UXID, autogenerate: true, prefix: "qry"}
  schema "querydesk_queries" do
    field :executed_at, :utc_datetime_usec
    field :failed, :boolean, default: false
    field :is_system, :boolean, default: false
    field :limit, :integer, default: 500
    field :query, :string
    field :run_on_approval, :boolean, default: false
    field :slack_channel, :string
    field :slack_message_ts, :string
    field :timeout, :integer, default: 10
    field :error, :string
    field :analyze, :boolean, default: false
    field :plan, :map

    belongs_to :organization, Organization
    belongs_to :credential, DatabaseCredential
    belongs_to :user, User

    has_many :approvals, QueryApproval
    has_many :comments, QueryComment

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [
      :credential_id,
      :error,
      :executed_at,
      :failed,
      :is_system,
      :limit,
      :organization_id,
      :query,
      :run_on_approval,
      :slack_channel,
      :slack_message_ts,
      :timeout,
      :user_id,
      :analyze,
      :plan
    ])
    |> validate_required([:query, :organization_id, :credential_id, :failed, :is_system, :analyze])
    |> maybe_override_limit()
  end

  defp maybe_override_limit(changeset) do
    query = get_field(changeset, :query) || ""
    limit = get_field(changeset, :limit) || 500

    with [_match, limit_str] <- ~r/LIMIT\s+(\d+)/i |> Regex.scan(query) |> List.last(),
         {query_limit, _rest} <- Integer.parse(limit_str),
         true <- query_limit > limit do
      put_change(changeset, :limit, query_limit)
    else
      _no_limit -> changeset
    end
  end
end
