defmodule DevhubWeb.Live.TerraDesk.DriftDetection do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Permissions

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.page_header title="Drift detection">
      <:actions>
        <.link_button
          :if={Permissions.can?(:manage_terraform, @organization_user)}
          phx-click={show_modal("add_schedule")}
        >
          Add schedule
        </.link_button>
      </:actions>
    </.page_header>
    """
  end
end
