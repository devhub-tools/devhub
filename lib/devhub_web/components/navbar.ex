defmodule DevhubWeb.Components.Navbar do
  @moduledoc false
  use DevhubWeb, :html

  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.User

  attr :active_tab, :string, required: true
  attr :user, User, required: true
  attr :organization, Organization, required: true

  def navbar(assigns) do
    products = assigns.organization.license.products
    only_querydesk? = products == [:querydesk]

    mode = if assigns.active_tab in [:query, :table], do: :mini, else: :full
    assigns = assign(assigns, mode: mode, only_querydesk?: only_querydesk?)

    ~H"""
    <nav class={[
      "bg-surface-1 inset-y-0 m-4 flex flex-col",
      if(@mode == :mini,
        do: "border-alpha-8 absolute w-16 rounded-l-lg border-r p-4",
        else: "fixed w-56 rounded-lg p-4"
      )
    ]}>
      <div class="flex grow flex-col gap-y-4">
        <.link navigate={~p"/"} class="flex w-full shrink-0">
          <.logo :if={@mode == :full and not @only_querydesk?} class="size-12 mx-auto" />
          <.icon
            :if={@mode == :full and @only_querydesk?}
            name="devhub-querydesk"
            class="size-12 mx-auto"
          />
          <.icon :if={@mode == :mini} name="devhub-querydesk" class="size-8 mx-auto" />
        </.link>
        <div class={["divide-alpha-4 flex flex-1 flex-col space-y-2", if(@mode == :mini, do: "mt-4")]}>
          <.product
            organization={@organization}
            mode={@mode}
            product={:dev_portal}
            title="Dev portal"
            icon="hero-chart-bar-square"
            active={@active_product == :dev_portal}
            items={[
              %{
                icon: "hero-home",
                title: "My portal",
                navigate: ~p"/",
                active: @active_tab == :my_portal
              },
              %{
                icon: "hero-chart-pie",
                title: "Metrics",
                navigate: ~p"/portal/metrics",
                active: @active_tab == :metrics
              },
              %{
                icon: "hero-calendar-days",
                title: "Planning",
                navigate: ~p"/portal/planning",
                active: @active_tab == :planning
              }
            ]}
          />

          <.product
            organization={@organization}
            mode={@mode}
            product={:querydesk}
            title="QueryDesk"
            icon="devhub-querydesk"
            active={@active_product == :querydesk}
            items={[
              %{
                icon: "hero-circle-stack",
                title: "Databases",
                navigate: ~p"/querydesk",
                active: @active_tab == :databases
              },
              %{
                icon: "hero-check-badge",
                title: "Pending queries",
                navigate: "/querydesk/pending-queries",
                active: @active_tab == :pending_queries,
                hide: not Code.ensure_loaded?(DevhubPrivateWeb.Live.QueryDesk.PendingQueries)
              },
              %{
                icon: "hero-chat-bubble-left-right",
                title: "AI assistant",
                navigate: ~p"/querydesk/ai",
                active: @active_tab == :ai_assistant
              },
              %{
                icon: "hero-book-open",
                title: "Query library",
                navigate: ~p"/querydesk/library",
                active: @active_tab == :query_library
              },
              %{
                icon: "hero-share",
                title: "Shared queries",
                navigate: ~p"/querydesk/shared-queries",
                active: @active_tab == :shared_queries
              },
              %{
                icon: "hero-tag",
                title: "Labels",
                navigate: ~p"/querydesk/labels",
                active: @active_tab == :labels
              },
              %{
                icon: "hero-chart-bar",
                title: "Dashboards",
                navigate: ~p"/dashboards",
                active: @active_tab == :dashboards
              },
              %{
                icon: "hero-arrow-path-rounded-square",
                title: "Workflows",
                navigate: ~p"/workflows",
                active: @active_tab == :workflows
              },
              %{
                icon: "hero-document-text",
                title: "Audit log",
                navigate: ~p"/querydesk/audit-log",
                active: @active_tab == :audit_log
              }
            ]}
          />

          <.product
            organization={@organization}
            mode={@mode}
            product={:coverbot}
            title="Coverbot"
            icon="devhub-coverbot"
            active={@active_product == :coverbot}
            items={[
              %{
                icon: "hero-document-check",
                title: "Code coverage",
                navigate: ~p"/coverbot",
                active: @active_tab == :coverbot
              },
              %{
                icon: "hero-clipboard-document-list",
                title: "Test reports",
                navigate: ~p"/coverbot/test-reports",
                active: @active_tab == :test_reports
              },
              %{
                icon: "devhub-uptime",
                title: "Uptime monitoring",
                navigate: ~p"/uptime",
                active: @active_tab == :uptime
              }
            ]}
          />

          <.product
            organization={@organization}
            mode={@mode}
            product={:terradesk}
            title="TerraDesk"
            icon="devhub-terradesk"
            active={@active_product == :terradesk}
            items={
              [
                %{
                  icon: "hero-cloud",
                  title: "Workspaces",
                  navigate: ~p"/terradesk",
                  active: @active_tab == :terradesk
                }
                # %{
                #   icon: "hero-clock",
                #   title: "Drift detection",
                #   navigate: ~p"/terradesk/drift-detection",
                #   active: @active_tab == :drift_detection
                # }
              ]
            }
          />
        </div>

        <ul class={[
          "mx-auto mt-auto flex items-center gap-x-2",
          if(@mode == :mini, do: "-ml-1 flex-col flex-col-reverse justify-between gap-y-1")
        ]}>
          <li class="flex items-center justify-center pt-1.5">
            <.dropdown id="profile">
              <:trigger>
                <span class="sr-only">Open user menu</span>
                <.user_image user={@user} class="size-7 rounded-full" />
              </:trigger>
              <div class="divide-alpha-8 bg-surface-4 absolute bottom-10 -left-8 w-44 origin-bottom-left divide-y rounded text-sm ring-1 ring-gray-100 ring-opacity-5">
                <div class="p-3">
                  <p class="text-alpha-64 mb-1 text-sm">Signed in as</p>
                  <div>
                    <p class="truncate text-sm">
                      {@user.name}
                    </p>
                    <p class="truncate text-sm text-gray-600">
                      {@user.email}
                    </p>
                  </div>
                </div>
                <div class="p-3">
                  <p class="text-alpha-64 mb-1 text-sm">Contact us</p>
                  <p class="text-sm">
                    support@devhub.tools
                  </p>
                </div>
                <.link href={~p"/auth/logout"} class="block p-3 text-sm">
                  Sign out
                </.link>
              </div>
            </.dropdown>
          </li>
          <li>
            <.link
              navigate={~p"/settings/account"}
              class="flex items-center gap-3 rounded-md p-1.5 text-sm text-gray-600 hover:bg-alpha-4 hover:text-gray-900"
            >
              <.icon name="hero-cog-6-tooth" class="size-7" />
            </.link>
          </li>
          <li>
            <.theme_toggle />
          </li>
        </ul>
      </div>
    </nav>
    """
  end

  attr :product, :atom, required: true
  attr :icon, :string, default: nil
  attr :title, :string, default: nil
  attr :items, :list, default: []
  attr :active, :boolean, default: false
  attr :mode, :atom, required: true
  attr :organization, Organization, required: true

  defp product(assigns) do
    number_of_products = length(assigns.organization.license.products)
    assigns = assign(assigns, number_of_products: number_of_products)

    ~H"""
    <div
      :if={@product in @organization.license.products}
      class="flex flex-col gap-y-1"
      id={"#{@product}-nav-container"}
    >
      <div
        :if={@number_of_products > 1 and @mode == :full}
        class="-mx-2 flex cursor-pointer items-center justify-between rounded-md p-2 hover:bg-alpha-4"
        role="button"
        phx-click={
          toggle("##{@product}-nav-items")
          |> JS.toggle_class("rotate-90",
            to: "##{@product}-nav-container .hero-chevron-right-mini"
          )
          |> JS.toggle_class("-rotate-90",
            to: "##{@product}-nav-container .hero-chevron-down-mini"
          )
        }
      >
        <span :if={@title} class="text-alpha-64 flex items-center gap-x-1 text-xs">
          <.icon name={@icon} class="size-4" />
          {@title}
        </span>
        <.icon
          name={(@active && "hero-chevron-down-mini") || "hero-chevron-right-mini"}
          class="size-4 text-alpha-40 transition-all"
        />
      </div>
      <ul
        id={"#{@product}-nav-items"}
        class={[
          "mb-2 transition-all",
          @active || @number_of_products <= 1 || "hidden",
          (@mode == :mini && "space-y-2") || "space-y-1"
        ]}
      >
        <li :for={item <- @items}>
          <.link
            :if={item[:hide] != true}
            navigate={item.navigate}
            class={[
              "flex items-center rounded-md text-sm text-gray-600 hover:bg-alpha-4 hover:text-gray-900",
              item.active && "bg-alpha-4 text-gray-900",
              (@mode == :mini && "size-8 mx-auto justify-center") || "gap-x-2 p-2"
            ]}
          >
            <div :if={@mode == :mini} class="tooltip-right tooltip">
              <.icon name={item.icon} class="size-6" />
              <span class="tooltiptext text-nowrap p-2">{item.title}</span>
            </div>

            <div :if={@mode == :full} class="flex items-center gap-x-1">
              <.icon name={item.icon} class="size-5" />
              <span class="text-alpha-64">{item.title}</span>
            </div>
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
