defmodule Devhub.Repo.Migrations.AddProductsToExistingOrgs do
  use Ecto.Migration

  def change do
    execute "UPDATE organizations SET license = jsonb_set(license, '{products}', '[\"querydesk\", \"terradesk\", \"dev_portal\", \"coverbot\"]')",
            ""
  end
end
