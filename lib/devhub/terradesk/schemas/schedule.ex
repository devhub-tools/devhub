defmodule Devhub.TerraDesk.Schemas.Schedule do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.TerraDesk.Schemas.Workspace
  alias Devhub.Users.Schemas.Organization
  alias Oban.Cron.Expression

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          cron_expression: String.t(),
          slack_channel: String.t() | nil,
          enabled: boolean()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "tfs"}
  schema "terraform_schedules" do
    field :name, :string
    field :cron_expression, :string
    field :slack_channel, :string
    field :enabled, :boolean, default: true

    belongs_to :organization, Organization
    many_to_many :workspaces, Workspace, join_through: "terraform_workspace_schedules"
  end

  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> cast(params, [:name, :cron_expression, :slack_channel, :enabled, :organization_id])
    |> validate_required([:name, :cron_expression, :organization_id])
    |> validate_cron_expression()
  end

  defp validate_cron_expression(changeset) do
    cron_expression = get_field(changeset, :cron_expression)

    case Expression.parse(cron_expression || "") do
      {:ok, _cron} -> changeset
      {:error, _error} -> add_error(changeset, :cron_expression, "is invalid")
    end
  end
end
