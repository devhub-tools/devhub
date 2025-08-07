defmodule Devhub.TerraDesk.Schemas.ScheduleTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk.Schemas.Schedule

  test "changeset/1" do
    assert %Ecto.Changeset{
             valid?: false,
             errors: [
               cron_expression: {"is invalid", []},
               name: {"can't be blank", [validation: :required]},
               cron_expression: {"can't be blank", [validation: :required]},
               organization_id: {"can't be blank", [validation: :required]}
             ]
           } =
             Schedule.changeset(%Schedule{}, %{})

    assert %Ecto.Changeset{valid?: false, errors: [cron_expression: {"is invalid", []}]} =
             Schedule.changeset(%Schedule{}, %{
               organization_id: "org_123",
               name: "my schedule",
               cron_expression: "0 0 * * * *"
             })

    assert %Ecto.Changeset{valid?: false, errors: [cron_expression: {"is invalid", []}]} =
             Schedule.changeset(%Schedule{}, %{
               organization_id: "org_123",
               name: "my schedule",
               cron_expression: "random"
             })

    assert %Ecto.Changeset{valid?: true} =
             Schedule.changeset(%Schedule{}, %{
               organization_id: "org_123",
               name: "my schedule",
               cron_expression: "0 0 * * *"
             })
  end
end
