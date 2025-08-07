defmodule DevhubWeb.Plugs.ContentSecurityPolicy do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    nonce = generate_nonce()
    csp_headers = csp_headers(nonce)

    conn
    |> assign(:csp_nonce, nonce)
    |> Phoenix.Controller.put_secure_browser_headers(csp_headers)
  end

  defp csp_headers(nonce) do
    csp =
      """
      default-src 'self';
      connect-src 'self';
      script-src 'self' 'nonce-#{nonce}';
      img-src data: 'self' w3.org/svg/2000 https://avatars.githubusercontent.com https://www.gravatar.com https://lh3.googleusercontent.com img.shields.io;
      font-src 'self' https://fonts.gstatic.com;
      style-src 'self' https://fonts.googleapis.com 'unsafe-inline';
      """

    %{"content-security-policy" => String.replace(csp, "\n", "")}
  end

  defp generate_nonce(size \\ 10), do: size |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
end
