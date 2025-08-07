defmodule Devhub.Users.Schemas.UserTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users.User

  test "name validation" do
    params = %{
      email: "example@devhub.com",
      external_id: "123",
      provider: "google",
      timezone: "America/Denver"
    }

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "a"))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "alice"))

    # cleans up spaces
    assert %{changes: %{name: "alice"}, errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "alice "))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "Robert Downey Jr."))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "Mia-Downey"))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "Mark O'neil"))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "Thomas Müler"))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "ßáçøñ"))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "أحمد"))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "فلسطين"))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "فيليپا"))

    # need to support github usernames
    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "Bristclair13"))

    assert %{errors: []} =
             User.changeset(%User{}, Map.put(params, :name, "Владимир"))

    assert %{errors: [{:name, {"we are unable to support your name", [validation: :format]}}]} =
             User.changeset(%User{}, Map.put(params, :name, "a-"))

    assert %{errors: [{:name, {"we are unable to support your name", [validation: :format]}}]} =
             User.changeset(%User{}, Map.put(params, :name, "Mark 'Oneil"))

    assert %{errors: [{:name, {"we are unable to support your name", [validation: :format]}}]} =
             User.changeset(%User{}, Map.put(params, :name, "a_a"))

    assert %{errors: [{:name, {"we are unable to support your name", [validation: :format]}}]} =
             User.changeset(%User{}, Map.put(params, :name, "mila.eddison"))

    # name too long
    assert %{
             errors: [
               name:
                 {"should be at most %{count} character(s)",
                  [{:count, 100}, {:validation, :length}, {:kind, :max}, {:type, :string}]}
             ]
           } =
             User.changeset(%User{}, Map.put(params, :name, String.duplicate("a", 101)))
  end

  test "email validation" do
    params = %{
      name: "Alice",
      external_id: "123",
      provider: "google",
      timezone: "America/Denver"
    }

    assert %{errors: [email: {"can't be blank", [validation: :required]}]} = User.changeset(%User{}, params)

    assert %{errors: []} = User.changeset(%User{}, Map.put(params, :email, "michael@devhub.tools"))

    assert %{errors: [{:email, {"has invalid format", [validation: :format]}}]} =
             User.changeset(%User{}, Map.put(params, :email, "michaeldevhub"))
  end
end
