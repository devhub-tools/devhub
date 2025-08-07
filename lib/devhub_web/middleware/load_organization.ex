defmodule DevhubWeb.Middleware.LoadOrganization.Plug do
  @moduledoc false
  import Plug.Conn

  alias Devhub.Users

  def init(opts), do: opts

  def call(conn, _opts) do
    assign(conn, :organization, Users.get_organization())
  end
end

defmodule DevhubWeb.Middleware.LoadOrganization.Hook do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Users

  def on_mount(:default, _params, _session, socket) do
    socket
    |> assign(organization: Users.get_organization())
    |> cont()
  end
end
