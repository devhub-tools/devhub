defmodule Devhub.Repo.Migrations.CoverageDeleteDuplicates do
  use Ecto.Migration

  import Ecto.Query

  alias Devhub.Repo

  def up do
    subquery =
      from(c in "coverage",
        group_by: [c.sha, c.repository_id],
        select: %{sha: c.sha, repository_id: c.repository_id, max_inserted_at: max(c.inserted_at)}
      )

    latest_records_ids =
      Repo.all(
        from(c in "coverage",
          inner_join: s in subquery(subquery),
          on:
            c.sha == s.sha and c.repository_id == s.repository_id and
              c.inserted_at == s.max_inserted_at,
          select: c.id
        )
      )

    Repo.delete_all(from(c in "coverage", where: c.id not in ^latest_records_ids))
  end

  def down, do: :ok
end
