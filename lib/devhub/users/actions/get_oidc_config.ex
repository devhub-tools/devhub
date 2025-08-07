defmodule Devhub.Users.Actions.GetOidcConfig do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Users.OIDC

  @callback get_oidc_config(Keyword.t()) ::
              {:ok, OIDC.t(), map()} | {:error, :oidc_config_not_found}
  def get_oidc_config(by, active \\ true) do
    query = from o in OIDC, where: ^by

    query =
      if active do
        from o in query,
          where: not is_nil(o.client_id),
          where: not is_nil(o.client_secret),
          where: not is_nil(o.discovery_document_uri)
      else
        query
      end

    case Repo.one(query) do
      %OIDC{} = oidc ->
        {:ok, oidc,
         %{
           discovery_document_uri: oidc.discovery_document_uri,
           client_id: oidc.client_id,
           client_secret: oidc.client_secret,
           response_type: "code",
           scope: "openid email",
           redirect_uri: "#{DevhubWeb.Endpoint.url()}/auth/oidc/callback"
         }}

      _error ->
        {:error, :oidc_config_not_found}
    end
  end
end
