defmodule Devhub.QueryDesk.Schemas.Database do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Agents.Schemas.Agent
  alias Devhub.QueryDesk.Schemas.DatabaseColumn
  alias Devhub.QueryDesk.Schemas.DatabaseCredential
  alias Devhub.QueryDesk.Schemas.UserPinnedDatabase
  alias Devhub.Types.EncryptedBinary
  alias Devhub.Users.Schemas.ObjectPermission
  alias Devhub.Users.Schemas.Organization

  @derive {Jason.Encoder,
           only: [
             :id,
             :api_id,
             :name,
             :adapter,
             :hostname,
             :port,
             :database,
             :ssl,
             :restrict_access,
             :group,
             :slack_channel,
             :inserted_at,
             :updated_at,
             :credentials,
             :agent_id
           ]}

  @derive {LiveSync.Watch,
           [
             subscription_key: :organization_id,
             table: "querydesk_databases"
           ]}

  @type t :: %__MODULE__{
          api_id: String.t() | nil,
          name: String.t(),
          adapter: :postgres | :mysql | :clickhouse,
          hostname: String.t(),
          port: integer() | nil,
          database: String.t(),
          slack_channel: String.t() | nil,
          ssl: boolean(),
          cacertfile: EncryptedBinary.t() | nil,
          keyfile: EncryptedBinary.t() | nil,
          certfile: EncryptedBinary.t() | nil,
          restrict_access: boolean(),
          group: String.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @redact Application.compile_env(:devhub, :compile_env) != :test

  @primary_key {:id, UXID, autogenerate: true, prefix: "db"}
  schema "querydesk_active_databases" do
    field :api_id, :string
    field :name, :string
    field :adapter, Ecto.Enum, values: [:postgres, :mysql, :clickhouse], default: :postgres
    field :hostname, :string
    field :port, :integer
    field :database, :string
    field :slack_channel, :string
    field :ssl, :boolean, default: false
    field :cacertfile, EncryptedBinary, redact: @redact
    field :keyfile, EncryptedBinary, redact: @redact
    field :certfile, EncryptedBinary, redact: @redact
    field :restrict_access, :boolean, default: false
    field :group, :string

    belongs_to :organization, Organization
    belongs_to :agent, Agent

    has_one :default_credential, DatabaseCredential, where: [default_credential: true]

    has_many :credentials, DatabaseCredential,
      preload_order: [asc: :position],
      on_replace: :delete

    has_many :columns, DatabaseColumn, preload_order: [asc: :position]

    has_many :permissions, ObjectPermission, foreign_key: :database_id, on_replace: :delete
    has_many :data_protection_policies, Devhub.QueryDesk.Schemas.DataProtectionPolicy

    has_many :user_pins, UserPinnedDatabase

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [
      :adapter,
      :agent_id,
      :api_id,
      :cacertfile,
      :certfile,
      :database,
      :group,
      :hostname,
      :port,
      :keyfile,
      :name,
      :organization_id,
      :restrict_access,
      :slack_channel,
      :ssl
    ])
    |> cast_assoc(:credentials,
      with: &DatabaseCredential.changeset/3,
      sort_param: :credential_sort,
      drop_param: :credential_drop
    )
    |> cast_assoc(:permissions,
      with: &ObjectPermission.changeset/2,
      sort_param: :permission_sort,
      drop_param: :permission_drop
    )
    |> validate_required([:organization_id, :adapter])
    |> unique_constraint([:organization_id, :api_id], name: :querydesk_databases_organization_id_api_id_index)
    |> unique_constraint([:organization_id, :name, :group],
      error_key: :name,
      message: "that name is already in use",
      name: :querydesk_databases_organization_id_name_group_index
    )
  end
end
