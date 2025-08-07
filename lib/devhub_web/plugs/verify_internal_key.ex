defmodule DevhubWeb.Plugs.VerifyInternalKey do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _params) do
    with [token] <- get_req_header(conn, "x-internal-key"),
         {:ok, data} <- Phoenix.Token.verify(DevhubWeb.Endpoint, "internal", token, max_age: 60 * 60 * 4) do
      assign(conn, :internal_key, data)
    else
      _error ->
        conn
        |> send_resp(401, "")
        |> halt()
    end
  end
end
