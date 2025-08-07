defmodule Devhub.Integrations.AI.Actions.GetConversations do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.AI.Schemas.Conversation
  alias Devhub.Users.Schemas.OrganizationUser

  @callback get_conversations(OrganizationUser.t(), Keyword.t()) :: [
              %{id: String.t(), title: String.t(), updated_at: DateTime.t()}
            ]
  def get_conversations(organization_user, filters) do
    query =
      from c in Conversation,
        where: c.organization_id == ^organization_user.organization_id,
        where: c.user_id == ^organization_user.user_id,
        order_by: [desc: c.updated_at],
        distinct: true,
        limit: 50

    query
    |> maybe_search(filters[:search])
    |> Devhub.Repo.all()
  end

  defp maybe_search(query, nil), do: query

  defp maybe_search(query, search) do
    query
    |> join(:left, [c], m in assoc(c, :messages))
    |> where([c, m], ilike(c.title, ^"%#{search}%") or ilike(m.message, ^"%#{search}%"))
  end
end
