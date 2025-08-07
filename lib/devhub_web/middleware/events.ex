defmodule DevhubWeb.Middleware.Events.Hook do
  @moduledoc false
  use DevhubWeb, :live_view

  def on_mount(:default, _params, _session, socket) do
    socket
    |> attach_hook(:events, :handle_event, &maybe_handle_event/3)
    |> cont()
  end

  defp maybe_handle_event("navigate", %{"path" => path}, socket) do
    socket |> push_navigate(to: path) |> halt()
  end

  defp maybe_handle_event("generate_proxy_password", _params, socket) do
    {:ok, proxy_password} =
      Devhub.Users.generate_proxy_password(
        socket.assigns.user,
        socket.assigns.organization.proxy_password_expiration_seconds
      )

    socket
    |> assign(proxy_password: proxy_password)
    |> halt()
  end

  defp maybe_handle_event("set_date_filter", %{"start_date" => start_date, "end_date" => end_date}, socket) do
    params =
      (socket.assigns.uri.query || "")
      |> URI.decode_query()
      |> Map.put("start_date", start_date)
      |> Map.put("end_date", end_date)
      |> URI.encode_query()

    socket |> push_patch(to: "#{socket.assigns.uri.path}?#{params}") |> halt()
  end

  defp maybe_handle_event(_event, _params, socket) do
    {:cont, socket}
  end
end
