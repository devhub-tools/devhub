defmodule Devhub.QueryDesk.Actions.CreateCommentTest do
  use Devhub.DataCase

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.QueryComment

  test "create_comment/1" do
    organization = insert(:organization)
    credential = insert(:database_credential, database: build(:database, organization: organization))
    user = insert(:user)
    query = insert(:query, organization: organization, user: user, credential: credential)

    assert {:ok, %QueryComment{comment: "This is a comment"}} =
             QueryDesk.create_comment(query, user, "This is a comment")
  end
end
