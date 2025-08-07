defmodule Devhub.Users.Schemas.Organization do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          installation_id: String.t(),
          private_key: binary(),
          license: license() | nil,
          mfa_required: boolean(),
          proxy_password_expiration_seconds: integer()
        }

  @type license :: %__MODULE__.License{
          base_price: Decimal.t(),
          expires_at: DateTime.t() | nil,
          extra_seats: integer(),
          free_trial: boolean(),
          included_seats: integer(),
          key: String.t() | nil,
          next_bill: Decimal.t(),
          plan: :core | :scale | :querydesk,
          price_per_seat: Decimal.t(),
          renew: boolean(),
          on_renewal: map() | nil
        }

  @redact Application.compile_env(:devhub, :compile_env) != :test

  @primary_key {:id, UXID, autogenerate: true, prefix: "org", size: :small}
  schema "organizations" do
    field :name, :string, default: "Default organization"
    field :installation_id, :string
    field :private_key, Devhub.Types.EncryptedBinary, redact: @redact
    field :mfa_required, :boolean, default: false
    field :proxy_password_expiration_seconds, :integer, default: 3600

    embeds_one :license, License, primary_key: false, on_replace: :update do
      field :base_price, :decimal
      field :expires_at, :utc_datetime
      field :extra_seats, :integer
      field :free_trial, :boolean, default: false
      field :has_payment_method, :boolean
      field :included_seats, :integer
      field :key, :string
      field :next_bill, :decimal
      field :on_renewal, :map
      field :plan, Ecto.Enum, values: [:querydesk, :scale, :enterprise]
      field :price_per_seat, :decimal
      field :products, {:array, Ecto.Enum}, values: [:coverbot, :dev_portal, :querydesk, :terradesk]
      field :renew, :boolean
    end

    embeds_one :onboarding, Onboarding, primary_key: false, on_replace: :update do
      field :invites, :boolean, default: false
      field :git_import_started, :boolean, default: false
      field :git, :boolean, default: false
      field :done, :boolean, default: false
    end

    has_many :organization_users, Devhub.Users.Schemas.OrganizationUser
    has_many :users, through: [:organization_users, :user]
    has_many :integrations, Devhub.Integrations.Schemas.Integration

    timestamps()
  end

  def create_changeset(org \\ %__MODULE__{}, params) do
    org
    |> cast(params, [:name])
    |> put_embed(:onboarding, %__MODULE__.Onboarding{})
  end

  def update_changeset(org, params) do
    org
    |> cast(params, [:name, :installation_id, :private_key, :mfa_required, :proxy_password_expiration_seconds])
    |> validate_required([:installation_id, :private_key])
    |> cast_embed(:onboarding, with: &onboarding_changeset/2)
    |> cast_embed(:license, with: &license_changeset/2)
  end

  def license_changeset(changeset, params \\ %{}) do
    params = Devhub.Utils.delete_if_empty(params, :products)

    cast(changeset, params, [
      :base_price,
      :expires_at,
      :extra_seats,
      :free_trial,
      :has_payment_method,
      :included_seats,
      :key,
      :next_bill,
      :on_renewal,
      :plan,
      :price_per_seat,
      :products,
      :renew
    ])
  end

  def onboarding_changeset(changeset, params \\ %{}) do
    cast(changeset, params, [:invites, :git_import_started, :git, :done])
  end
end
