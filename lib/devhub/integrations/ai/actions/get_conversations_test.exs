defmodule Devhub.Integrations.AI.Actions.GetConversationsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.AI

  test "can search conversations" do
    organization = insert(:organization)

    organization_user =
      insert(:organization_user, organization: organization, user: build(:user), permissions: %{super_admin: true})

    _excluded_conversation =
      insert(:ai_conversation,
        organization: organization,
        user: organization_user.user,
        messages: [build(:ai_conversation_message, organization: organization)]
      )

    %{id: included_by_title} =
      insert(:ai_conversation,
        organization: organization,
        user: organization_user.user,
        title: "Get Commits",
        messages: [build(:ai_conversation_message, organization: organization)]
      )

    %{id: included_by_message} =
      insert(:ai_conversation,
        organization: organization,
        user: organization_user.user,
        messages: [build(:ai_conversation_message, organization: organization, message: "select * from commits")]
      )

    assert [%{id: ^included_by_message}, %{id: ^included_by_title}] =
             AI.get_conversations(organization_user, search: "commits")
  end
end
