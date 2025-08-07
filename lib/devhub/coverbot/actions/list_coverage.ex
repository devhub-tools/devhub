defmodule Devhub.Coverbot.Actions.ListCoverage do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Coverbot.Coverage
  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization

  @callback list_coverage(Organization.t()) :: [
              %{
                id: String.t(),
                owner: String.t(),
                name: String.t(),
                ref: String.t(),
                percentage: Decimal.t()
              }
            ]
  def list_coverage(organization) do
    subquery =
      from c in Coverage,
        join: r in assoc(c, :repository),
        where: c.organization_id == ^organization.id,
        where: c.is_for_default_branch,
        select: %{
          seqnum:
            fragment(
              "row_number() OVER (PARTITION BY ? ORDER BY ? DESC)",
              c.repository_id,
              c.inserted_at
            ),
          id: r.id,
          owner: r.owner,
          name: r.name,
          ref: c.ref,
          percentage: c.percentage,
          inserted_at: c.inserted_at
        }

    query =
      from d in subquery(subquery),
        where: d.seqnum == 1,
        select: %{
          id: d.id,
          owner: d.owner,
          name: d.name,
          ref: d.ref,
          percentage: d.percentage
        },
        order_by: [desc: d.inserted_at]

    Repo.all(query)
  end
end
