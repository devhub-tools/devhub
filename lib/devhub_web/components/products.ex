defmodule DevhubWeb.Components.Products do
  @moduledoc false
  use DevhubWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mt-4 grid grid-cols-2 gap-4">
      <.product
        name="QueryDesk"
        icon="devhub-querydesk"
        product={:querydesk}
        description="Compliant, secure access to all of your databases"
        organization={@organization}
        myself={@myself}
        features={[
          "Connect securely through a browser or your own database client",
          "Require query reviews for write access",
          "Configure data protection rules to simplify compliance",
          "Audit log of all queries",
          "Use an AI assistant to write queries",
          "Setup workflows to automate your queries"
        ]}
      />

      <.product
        name="Developer portal"
        icon="hero-chart-bar-square"
        product={:dev_portal}
        beta={true}
        description="Get insight into your engineering team"
        organization={@organization}
        myself={@myself}
        features={[
          "Provide developers with an individualized dashboard",
          "View metrics for your entire organization or by team",
          "Plan and visualize what all of your teams are working on",
          "Custom integrations and metrics available"
        ]}
      />

      <.product
        name="TerraDesk"
        icon="devhub-terradesk"
        product={:terradesk}
        beta={true}
        description="Manage your infrastructure securely"
        organization={@organization}
        myself={@myself}
        features={[
          "Manage IaC with Terraform or Tofu",
          "Securely manage your infrastructure with on-prem runners",
          "Drift detection (coming soon)"
        ]}
      />

      <.product
        name="Coverbot"
        icon="devhub-coverbot"
        product={:coverbot}
        beta={true}
        description="Observability tools for your code and infrastructure"
        organization={@organization}
        myself={@myself}
        features={[
          "Code coverage tracking",
          "PR code coverage patch viewer",
          "Flaky test detection (coming soon)",
          "Service uptime/latency monitoring"
        ]}
      />
    </div>
    """
  end

  def handle_event("activate", %{"product" => product}, socket) do
    {:ok, organization} =
      Devhub.Users.update_organization(socket.assigns.organization, %{
        license: %{products: [product | socket.assigns.organization.license.products]}
      })

    if product == "dev_portal" do
      socket
      |> push_navigate(to: ~p"/settings/integrations/github")
      |> noreply()
    else
      socket
      |> assign(organization: organization)
      |> put_flash(:info, "Product activated")
      |> noreply()
    end
  end

  attr :beta, :boolean, default: false
  attr :description, :string
  attr :icon, :string
  attr :name, :string
  attr :product, :atom
  attr :organization, Organization
  attr :features, :list, default: []
  attr :myself, :any

  defp product(assigns) do
    ~H"""
    <div class="bg-surface-1 rounded-lg p-4">
      <div class="flex justify-between">
        <div>
          <div class="flex items-center gap-x-2 text-xl font-semibold">
            <.icon name={@icon} class="size-8" />{@name}
            <.badge :if={@beta} label="Beta" size="sm" />
          </div>
          <div class="text-alpha-64 mt-2">
            {@description}
          </div>
        </div>

        <div>
          <.badge :if={@product in @organization.license.products} color="blue" label="Enabled" />
          <.button
            :if={@product not in @organization.license.products}
            phx-click="activate"
            phx-value-product={@product}
            phx-target={@myself}
          >
            Enable
          </.button>
        </div>
      </div>

      <h2 class="mt-4 font-semibold">Features</h2>
      <ul class="mt-1 space-y-1 text-sm text-gray-600">
        <li :for={feature <- @features}>
          <.icon name="hero-check-mini" class="size-4 text-blue-600" />
          {feature}
        </li>
      </ul>
    </div>
    """
  end
end
