defmodule DevhubWeb.Middleware.LiveFlash do
  @moduledoc false
  use DevhubWeb, :live_view

  def on_mount(:default, _params, _session, socket) do
    socket |> attach_hook(:flash, :handle_info, &handle_flash/2) |> cont()
  end

  def push_flash(socket, key, msg) do
    send(self(), {:flash, key, msg})
    socket
  end

  defp handle_flash({:flash, key, msg}, socket) do
    {:halt, put_flash(socket, key, msg)}
  end

  defp handle_flash(_otherwise, socket) do
    {:cont, socket}
  end
end
