defmodule DevhubWeb.GitHubController do
  use DevhubWeb, :controller

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub

  def setup_app(%{assigns: %{organization_user: %{permissions: %{super_admin: true}}}} = conn, %{"code" => code}) do
    {:ok, app} = GitHub.register_app(conn.assigns.organization, code)

    # give github enough time to have the app created before redirecting to it
    if !Devhub.test?(), do: :timer.sleep(1000)

    redirect(conn, external: "https://github.com/apps/#{app.slug}/installations/new")
  end

  def setup_app(conn, _params) do
    conn
    |> put_flash(:error, "You don't have permission to setup GitHub for this organization.")
    |> redirect(to: ~p"/")
  end

  def setup_installation(%{assigns: %{organization_user: %{permissions: %{super_admin: true}}}} = conn, %{
        "installation_id" => installation_id
      }) do
    {:ok, %{"account" => %{"login" => login}}} =
      GitHub.get_installation(conn.assigns.organization.id, installation_id)

    {:ok, integration} =
      Integrations.create(%{
        organization_id: conn.assigns.organization.id,
        provider: :github,
        external_id: installation_id,
        settings: %{"login" => login}
      })

    GitHub.import_users(integration)
    GitHub.import_repositories(integration)

    redirect(conn, to: ~p"/settings/integrations/github/setup")
  end

  def setup_installation(conn, _params) do
    conn
    |> put_flash(:error, "You don't have permission to setup GitHub for this organization.")
    |> redirect(to: ~p"/")
  end
end
