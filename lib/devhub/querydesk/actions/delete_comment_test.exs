defmodule Devhub.QueryDesk.Actions.DeleteCommentTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.QueryComment
  alias Devhub.Repo

  test "success" do
    organization = insert(:organization)
    credential = insert(:database_credential, database: build(:database, organization: organization))
    user = insert(:user)
    query = insert(:query, organization: organization, user: user, credential: credential)
    comment = insert(:comment, query: query, created_by_user: user, organization: organization)

    assert {:ok, _query} = QueryDesk.delete_comment(comment)
    assert [] = Repo.all(QueryComment)
  end
end
