defmodule Devhub.Users.Schemas.ObjectPermissionTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users.Schemas.ObjectPermission

  test "returns an error changeset when organization_user_id and role_id are not provided" do
    assert %Ecto.Changeset{
             valid?: false,
             errors: [
               {:organization_user_id, {"must have either an organization user or role assigned", []}}
             ]
           } = ObjectPermission.changeset(%{permission: :approve})
  end

  test "returns an error changeset when organization_user_id and role_id are provided" do
    assert %Ecto.Changeset{
             valid?: false,
             errors: [
               {:organization_user_id, {"must have either an organization user or role assigned", []}}
             ]
           } = ObjectPermission.changeset(%{permission: :approve, organization_user_id: "123", role_id: "123"})
  end

  test "returns a valid changeset when organization_user_id is provided" do
    assert %Ecto.Changeset{valid?: true} =
             ObjectPermission.changeset(%{permission: :approve, organization_user_id: "123"})
  end

  test "returns a valid changeset when role_id is provided" do
    assert %Ecto.Changeset{valid?: true} = ObjectPermission.changeset(%{permission: :approve, role_id: "123"})
  end
end
