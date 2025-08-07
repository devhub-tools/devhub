defmodule Devhub.Integrations.GitHub.Actions.RegisterApp do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Schemas.GitHubApp
  alias Devhub.Repo

  @callback register_app(Organization.t(), String.t()) :: {:ok, GithubApp.t()} | {:error, Ecto.Changeset.t()}
  def register_app(organization, code) do
    {:ok,
     %{
       body: %{
         "id" => external_id,
         "slug" => slug,
         "client_id" => client_id,
         "client_secret" => client_secret,
         "webhook_secret" => webhook_secret,
         "pem" => private_key
       }
     }} = Devhub.Integrations.GitHub.Client.convert_code(code)

    %{
      external_id: external_id,
      slug: slug,
      client_id: client_id,
      client_secret: client_secret,
      webhook_secret: webhook_secret,
      private_key: private_key,
      organization_id: organization.id
    }
    |> GitHubApp.changeset()
    |> Repo.insert()
  end
end
