defmodule DevhubWeb.Components.Features do
  @moduledoc false
  use DevhubWeb, :html

  def features(assigns) do
    ~H"""
    <div class="flex flex-col gap-y-16 text-left">
      <%= for section <- features() do %>
        <div class="divide-alpha-4 grid grid-cols-5 divide-y">
          <div class="col-span-5">
            <div class="border-alpha-4 border-b pb-4 text-sm font-semibold">
              {section.section}
              <div class="absolute inset-x-8 mt-4 h-px"></div>
            </div>
          </div>
          <%= for feature <- section.features do %>
            <div class="col-span-2 py-4 text-sm font-normal">
              {feature.name}
              <div class="absolute inset-x-8 mt-4 h-px"></div>
            </div>
            <div class="px-6 py-4 text-center xl:px-8">
              <.icon
                :if={feature.free[:included] == true}
                name="hero-check"
                class="h-5 w-5 text-blue-500"
              />
              <.icon
                :if={feature.free[:included] == false}
                name="hero-minus-small"
                class="h-5 w-5 text-gray-500"
              />
              <div :if={feature.free[:text]} class="text-center text-sm text-gray-500">
                {feature.free[:text]}
              </div>
            </div>
            <div class="px-6 py-4 text-center xl:px-8">
              <.icon
                :if={feature.core[:included] == true}
                name="hero-check"
                class="h-5 w-5 text-blue-500"
              />
              <.icon
                :if={feature.core[:included] == false}
                name="hero-minus-small"
                class="h-5 w-5 text-gray-500"
              />
              <div :if={feature.core[:text]} class="text-center text-sm text-gray-500">
                {feature.core[:text]}
              </div>
            </div>
            <div class="px-6 py-4 text-center xl:px-8">
              <.icon
                :if={feature.scale[:included] == true}
                name="hero-check"
                class="h-5 w-5 text-blue-500"
              />
              <div :if={feature.scale[:text]} class="text-center text-sm text-gray-500">
                {feature.scale[:text]}
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp features do
    [
      %{
        section: "Base",
        features: [
          %{
            name: "Included users",
            free: %{text: "10 (max)"},
            core: %{text: "25"},
            scale: %{text: "25"}
          },
          %{
            name: "Additional users",
            free: %{included: false},
            core: %{text: "$10/user"},
            scale: %{text: "$15/user"}
          },
          %{
            name: "Self hosted",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "RBAC",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "OIDC/SSO",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          }
        ]
      },
      %{
        section: "Developer Portal",
        features: [
          %{
            name: "GitHub integration",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Linear integration",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Developer dashboard",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Organization dashboard",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "View detailed metric data",
            free: %{included: false},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Workflows",
            free: %{included: false},
            core: %{included: false},
            scale: %{included: true}
          },
          %{
            name: "Team dashboards",
            free: %{included: false},
            core: %{included: false},
            scale: %{included: true}
          },
          %{
            name: "Priority planning",
            free: %{included: false},
            core: %{included: false},
            scale: %{included: true}
          },
          %{
            name: "Custom integrations",
            free: %{included: false},
            core: %{included: false},
            scale: %{included: true}
          },
          %{
            name: "Custom metrics",
            free: %{included: false},
            core: %{included: false},
            scale: %{included: true}
          }
        ]
      },
      %{
        section: "QueryDesk",
        features: [
          %{
            name: "Browser based database client",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Database proxy (use your own database client)",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "AI autocomplete and query recommendations",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Unlimited database connections and queries",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Agent for private networks",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Query reviews",
            free: %{included: false},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Data protection",
            free: %{included: false},
            core: %{included: false},
            scale: %{included: true}
          },
          %{
            name: "Audit log",
            free: %{included: false},
            core: %{included: false},
            scale: %{included: true}
          }
        ]
      },
      %{
        section: "Coverbot",
        features: [
          %{
            name: "Code coverage tracking",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "GitHub PR status checks",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Dashboard showing coverage over time",
            free: %{included: false},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Patch coverage diff viewer for PRs",
            free: %{included: false},
            core: %{included: true},
            scale: %{included: true}
          }
        ]
      },
      %{
        section: "Uptime Monitoring",
        features: [
          %{
            name: "Monitor service uptime and latncy",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "View historical uptime data",
            free: %{included: false},
            core: %{included: true},
            scale: %{included: true}
          }
        ]
      },
      %{
        section: "Support",
        features: [
          %{
            name: "Email support",
            free: %{included: true},
            core: %{included: true},
            scale: %{included: true}
          },
          %{
            name: "Slack",
            free: %{included: false},
            core: %{included: false},
            scale: %{included: true}
          },
          %{
            name: "1:1 onboarding tour",
            free: %{included: false},
            core: %{included: false},
            scale: %{included: true}
          }
        ]
      }
    ]
  end
end
