defmodule Devhub.QueryDesk.Actions.ListCredentialOptions do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk

  @callback list_credential_options(OrganizationUser.t()) :: [map()]
  def list_credential_options(organization_user) do
    organization_user
    |> QueryDesk.list_databases()
    |> Devhub.Repo.preload(:credentials)
    |> Enum.flat_map(fn database ->
      Enum.map(
        database.credentials,
        fn credential ->
          name =
            if database.group do
              "#{credential.username} - #{database.name} (#{database.group})"
            else
              "#{credential.username} - #{database.name}"
            end

          %{
            id: credential.id,
            name: name,
            username: credential.username,
            reviews_required: credential.reviews_required,
            database: database.name,
            group: database.group
          }
        end
      )
    end)
  end
end
