defmodule DevhubWeb.Middleware.Nav.Hook do
  @moduledoc false
  use DevhubWeb, :live_view

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :active_tab, :handle_params, &set_active_tab/3)}
  end

  defp set_active_tab(_params, url, socket) do
    %{path: path} = uri = URI.parse(url)
    {active_product, active_tab} = socket.view |> Module.split() |> tab_for(path)

    if is_nil(active_product) or active_product in socket.assigns.organization.license.products do
      socket |> assign(active_product: active_product, active_tab: active_tab, active_path: path, uri: uri) |> cont()
    else
      home_page = DevhubWeb.home_page(socket.assigns.organization)
      socket |> push_navigate(to: home_page) |> halt()
    end
  end

  # coverbot
  defp tab_for(["DevhubWeb", "Live", "Coverbot", "TestReports" | _rest], _path), do: {:coverbot, :test_reports}
  defp tab_for(["DevhubWeb", "Live", "Coverbot" | _rest], _path), do: {:coverbot, :coverbot}
  defp tab_for(["DevhubWeb", "Live", "Uptime" | _rest], _path), do: {:coverbot, :uptime}

  # portal
  defp tab_for(["DevhubWeb", "Live", "Portal", "Planning"], _path), do: {:dev_portal, :planning}
  defp tab_for(["DevhubWeb", "Live", "Portal", "MyPortal"], _path), do: {:dev_portal, :my_portal}
  defp tab_for(["DevhubWeb", "Live", "Portal" | _rest], _path), do: {:dev_portal, :metrics}

  # querydesk
  defp tab_for(["DevhubWeb", "Live", "Workflows" | _rest], _path), do: {:querydesk, :workflows}
  defp tab_for(["DevhubWeb", "Live", "Dashboards" | _rest], _path), do: {:querydesk, :dashboards}
  defp tab_for(["DevhubWeb", "Live", "QueryDesk", "AuditLog"], _path), do: {:querydesk, :audit_log}
  defp tab_for(["DevhubWeb", "Live", "QueryDesk", "Labels"], _path), do: {:querydesk, :labels}
  defp tab_for(["DevhubWeb", "Live", "QueryDesk", "PendingQueries"], _path), do: {:querydesk, :pending_queries}
  defp tab_for(["DevhubWeb", "Live", "QueryDesk", "Query"], _path), do: {:querydesk, :query}
  defp tab_for(["DevhubWeb", "Live", "QueryDesk", "SharedQueries"], _path), do: {:querydesk, :shared_queries}
  defp tab_for(["DevhubWeb", "Live", "QueryDesk", "Table"], _path), do: {:querydesk, :table}
  defp tab_for(["DevhubWeb", "Live", "QueryDesk" | _rest], _path), do: {:querydesk, :databases}

  # terradesk
  defp tab_for(["DevhubWeb", "Live", "TerraDesk", "DriftDetection"], _path), do: {:terradesk, :drift_detection}
  defp tab_for(["DevhubWeb", "Live", "TerraDesk" | _rest], _path), do: {:terradesk, :terradesk}

  defp tab_for(_no_match, _path), do: {nil, nil}
end
