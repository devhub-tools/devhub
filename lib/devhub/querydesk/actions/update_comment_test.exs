defmodule Devhub.QueryDesk.Actions.UpdateCommentTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.QueryComment

  test "success" do
    organization = insert(:organization)
    credential = insert(:database_credential, database: build(:database, organization: organization))
    user = insert(:user)
    query = insert(:query, organization: organization, user: user, credential: credential)

    comment =
      insert(:comment,
        query: query,
        created_by_user: user,
        organization: organization,
        comment: "This is a comment"
      )

    assert {:ok, %QueryComment{comment: "This is a comment that is updated"}} =
             QueryDesk.update_comment(comment, %{comment: "This is a comment that is updated"})
  end
end
