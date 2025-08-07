defmodule Devhub.Coverbot.Actions.ListRepositoryRefsTest do
  @moduledoc false
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "success" do
    organization = insert(:organization)
    repository = insert(:repository, organization: organization)

    insert(:coverage, organization: organization, repository: repository, ref: "refs/pulls/49")
    %{id: main_id} = insert(:coverage, organization: organization, repository: repository, ref: "refs/heads/main")
    %{id: pr_id} = insert(:coverage, organization: organization, repository: repository, ref: "refs/pulls/49")

    assert [%{id: ^pr_id}, %{id: ^main_id}] = Coverbot.list_repository_refs(repository_id: repository.id)
  end
end
