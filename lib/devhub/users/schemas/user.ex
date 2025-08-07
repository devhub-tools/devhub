defmodule Devhub.Users.User do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          name: String.t(),
          picture: String.t(),
          external_id: String.t(),
          email: String.t(),
          provider: String.t(),
          timezone: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "usr"}
  schema "users" do
    field :name, :string
    field :email, :string
    field :picture, :string
    field :external_id, :string
    field :provider, :string
    field :timezone, :string, default: "America/Denver"
    field :enable_query_completion, :boolean, default: false
    field :preferences, :map

    embeds_one :proxy_password, ProxyPassword, on_replace: :delete do
      field :salt, :string
      field :stored_key, :string
      field :server_key, :string
      field :expires_at, :utc_datetime
    end

    has_many :organization_users, Devhub.Users.Schemas.OrganizationUser
    has_many :passkeys, Devhub.Users.Schemas.Passkey

    timestamps()
  end

  def changeset(user \\ %__MODULE__{}, params) do
    user
    |> cast(params, [:name, :email, :picture, :external_id, :provider, :timezone, :enable_query_completion, :preferences])
    |> validate_required([:email, :external_id, :provider, :timezone])
    |> update_change(:name, &if(&1, do: String.trim(&1), else: &1))
    |> validate_name()
    |> validate_email()
    |> cast_embed(:proxy_password, with: &proxy_password_changeset/2)
    |> unique_constraint([:provider, :external_id])
    |> unique_constraint([:email])
  end

  defp validate_name(changeset) do
    changeset
    |> validate_format(
      :name,
      ~r/^[a-zA-Z0-9\xC0-\x{FFFF}]+([ \-']{0,1}[a-zA-Z0-9\xC0-\x{FFFF}]+){0,2}[.]{0,1}$/u,
      message: "we are unable to support your name"
    )
    |> validate_length(:name, min: 1, max: 100)
  end

  defp validate_email(changeset) do
    validate_format(
      changeset,
      :email,
      ~r/^[--9^-~A-Z!#-'*+=?]+@[a-z0-9A-Z](?:[a-z0-9A-Z-]{0,61}[a-z0-9A-Z]|)(?:\.[a-z0-9A-Z](?:[a-z0-9A-Z-]{0,61}[a-z0-9A-Z]|))*$/
    )
  end

  defp proxy_password_changeset(embed, params) do
    cast(embed, params, [:salt, :stored_key, :server_key, :expires_at])
  end
end
