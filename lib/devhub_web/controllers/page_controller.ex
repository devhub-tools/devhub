defmodule DevhubWeb.PageController do
  use DevhubWeb, :controller

  alias Devhub.Licensing

  def license_expired(conn, _params) do
    render(conn, :license_expired, layout: false)
  end

  def no_license(conn, _params) do
    render(conn, :no_license, layout: false)
  end

  def not_authenticated(conn, _params) do
    render(conn, :not_authenticated, layout: false)
  end

  if Code.ensure_loaded?(Licensing) do
    def start_trial(conn, %{"plan" => plan}) do
      %{organization: organization, user: user} = conn.assigns

      {:ok, _organization} = Licensing.subscribe(organization, plan, user.email)

      case plan do
        "querydesk" ->
          redirect(conn, to: ~p"/querydesk")
      end
    end
  end
end
