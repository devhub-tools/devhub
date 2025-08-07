defmodule DevhubWeb.Components.SettingsTabs do
  @moduledoc false
  use DevhubWeb, :html

  alias Devhub.Permissions

  def settings_tabs(assigns) do
    organization_user = assigns.organization_user

    tabs =
      Enum.filter(
        [
          %{title: "Account", link: ~p"/settings/account", icon: "hero-building-office-2", visible: true},
          %{
            title: "Billing",
            link: "/settings/billing",
            icon: "devhub-credit-card",
            visible:
              Permissions.can?(:manage_billing, organization_user) and
                Code.ensure_loaded?(DevhubPrivateWeb.Live.Settings.Billing)
          },
          %{
            title: "Users",
            link: ~p"/settings/users",
            icon: "devhub-user",
            visible: Permissions.can?(:manage_users, organization_user)
          },
          %{
            title: "Teams",
            link: ~p"/settings/teams",
            icon: "devhub-users",
            visible: Permissions.can?(:manage_users, organization_user)
          },
          %{
            title: "Roles",
            link: "/settings/roles",
            icon: "hero-check-circle",
            visible:
              Permissions.can?(:manage_roles, organization_user) and
                Code.ensure_loaded?(DevhubPrivateWeb.Live.Settings.Roles)
          },
          %{
            title: "Integrations",
            link: ~p"/settings/integrations",
            icon: "hero-cube",
            visible: Permissions.can?(:manage_integrations, organization_user)
          },
          %{
            title: "API Keys",
            link: ~p"/settings/api-keys",
            icon: "devhub-key",
            visible: Permissions.can?(:manage_settings, organization_user)
          },
          %{
            title: "Agents",
            link: ~p"/settings/agents",
            icon: "hero-cloud",
            visible: Permissions.can?(:manage_settings, organization_user)
          },
          %{
            title: "OIDC",
            link: ~p"/settings/oidc",
            icon: "hero-lock-closed",
            visible: Permissions.can?(:manage_settings, organization_user)
          }
        ],
        & &1[:visible]
      )

    assigns = assign(assigns, tabs: tabs)

    ~H"""
    <.tabs active_path={@active_path} tabs={@tabs} />
    """
  end
end
