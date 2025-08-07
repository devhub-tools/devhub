defmodule DevhubWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: DevhubWeb.Gettext

  alias DevhubWeb.Components
  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS

  defdelegate agent_status(assigns), to: Components.AgentStatus
  defdelegate badge(assigns), to: Components.Badge
  defdelegate button(assigns), to: Components.Button
  defdelegate details(assigns), to: Components.Details
  defdelegate drawer(assigns), to: Components.Drawer
  defdelegate dropdown_with_search(assigns), to: Components.DropdownWithSearch
  defdelegate hover_card(assigns), to: Components.HoverCard
  defdelegate link_button(assigns), to: Components.Button
  defdelegate multi_select(assigns), to: Components.MultiSelect
  defdelegate navbar(assigns), to: Components.Navbar
  defdelegate object_label(assigns), to: Components.ObjectLabel
  defdelegate page_header(assigns), to: Components.PageHeader
  defdelegate select_with_search(assigns), to: Components.SelectWithSearch
  defdelegate shield_badge(assigns), to: Components.ShieldBadge
  defdelegate tabs(assigns), to: Components.Tabs
  defdelegate toggle_button(assigns), to: Components.ToggleButton
  defdelegate user_block(assigns), to: Components.UserBlock
  defdelegate user_image(assigns), to: Components.UserImage

  # QueryDesk
  defdelegate column_filter(assigns), to: Components.QueryDesk.ColumnFilter
  defdelegate credential_dropdown(assigns), to: Components.CredentialDropdown
  defdelegate database_table_list(assigns), to: Components.DatabaseTableList
  defdelegate edit_query_modal(assigns), to: Components.Querydesk.EditQueryModal
  defdelegate formatted_query(assigns), to: Components.Querydesk.FormattedQuery
  defdelegate query_form(assigns), to: Components.QueryForm
  defdelegate query_summary(assigns), to: Components.QuerySummary
  defdelegate run_query_modal(assigns), to: Components.Querydesk.RunQueryModal

  # TerraDesk

  # Uptime
  defdelegate check_status(assigns), to: Components.Uptime.CheckStatus
  defdelegate check_indicator(assigns), to: Components.Uptime.CheckIndicator
  defdelegate service_checks_summary(assigns), to: Components.Uptime.ServiceChecksSummary

  # Integrations
  defdelegate github_app_setup(assigns), to: Components.Integrations.GitHubAppSetup

  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  def logo(assigns) do
    ~H"""
    <svg
      width="198"
      height="185"
      viewBox="0 0 198 185"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      {@rest}
    >
      <path
        d="M154.8 11.27C158.8 10.66 162.76 10.77 166.57 12.35C166.91 12.49 167.28 12.55 168 12.75C163.29 7.19 157.94 3.15 151.62 0C151.37 0.64 151.19 0.97 151.1 1.33C150.66 2.95 150.22 4.58 149.83 6.21C149.26 8.6 152.34 11.65 154.8 11.27Z"
        fill="currentColor"
      />
      <path
        d="M197.05 46C193.03 42.98 190.31 39.1 188.35 34.49C185.31 27.38 180.13 22.19 173.18 18.79C166.9 15.72 160.4 14.24 153.38 15.54C152.56 15.69 151.31 15.13 150.68 14.48C145.52 9.25 139.57 5.21 132.77 2.25C132.6 2.59 132.37 2.89 132.28 3.23C129.97 11.17 129.45 19.19 131.22 27.31C131.35 27.9 131.31 28.66 131.03 29.18C128.84 33.44 126.7 37.74 124.39 41.93C116.57 56.08 106.94 59.18 83.76 59.18C60.58 59.18 34.86 91.37 21.1 105.78L17.55 109.33C16.21 110.67 16.14 112.94 17.55 114.22C18.18 114.79 18.97 115.07 19.76 115.07C20.6 115.07 21.44 114.75 22.08 114.11L34.27 101.92L47.45 88.91C52.08 84.71 55.76 83.45 61.93 88.61C63.35 89.79 63.43 91.95 62.13 93.26L59.59 95.8C56.18 99.21 56.18 104.73 59.57 108.15C53.12 110.84 44.43 118.73 41.16 128.82C39.26 134.69 36.14 141.48 33.24 146.8C31.77 149.49 34.31 152.12 37.28 151.37C41.31 150.35 46.37 149.9 54.55 147.28C63.57 144.39 68.3 139.81 71.6 136.69C73.02 135.35 71.52 133.03 69.72 133.79C61.23 137.42 49.8 140.76 52.69 131.7C56.62 119.34 63.6 114.85 65.32 113.9L69.44 118.02C67.07 119.82 64.49 123.74 62.75 126.72C62.01 127.98 63.27 129.47 64.64 128.96C66.18 128.38 67.81 127.81 68.77 127.6C73.79 126.47 75.13 124.85 75.48 124.06L79.24 127.82C82.25 130.83 86.91 131.18 90.31 128.88C96.71 125.29 102.41 115.96 111.6 112.14C131.14 103.99 148.51 103.49 155.03 78.22C157.27 69.54 164.91 65.05 173.5 62.9C177.08 62.02 180.77 61.55 184.3 60.53C190.81 58.64 195.6 54.74 197.55 47.99C197.72 47.4 197.5 46.31 197.06 45.99L197.05 46ZM181.44 53.81C177.99 53.79 174.47 53.32 171.1 52.55C165.58 51.27 160.07 50.45 154.41 51.07C152.35 51.3 151.49 50.08 150.82 48.48C147.94 41.59 151.21 32.86 158.03 29.2C165.4 25.24 174.64 27.31 178.59 34.66C181.58 40.21 185.68 44.36 190.6 47.97C190.9 48.18 191.16 48.46 191.59 48.83C189.01 52.37 185.43 53.84 181.45 53.82L181.44 53.81Z"
        fill="currentColor"
      />
      <path
        d="M23.36 85.15C24.2 85.15 25.04 84.83 25.68 84.19L54.94 54.93C56.22 53.65 56.22 51.56 54.94 50.28C53.66 49 51.57 49 50.29 50.28L21.03 79.54C19.75 80.82 19.75 82.91 21.03 84.19C21.67 84.83 22.51 85.15 23.35 85.15H23.36Z"
        fill="currentColor"
      />
      <path
        d="M8.91001 99.6C9.75001 99.6 10.59 99.28 11.23 98.64L15.48 94.39C16.76 93.11 16.76 91.02 15.48 89.74C14.2 88.46 12.11 88.46 10.83 89.74L6.58001 93.99C5.30001 95.27 5.30001 97.36 6.58001 98.64C7.22001 99.28 8.06001 99.6 8.90001 99.6H8.91001Z"
        fill="currentColor"
      />
      <path
        d="M159.75 98.63L151.25 107.13C149.97 108.41 149.97 110.5 151.25 111.78C151.89 112.42 152.73 112.74 153.57 112.74C154.41 112.74 155.25 112.42 155.89 111.78L164.39 103.28C165.67 102 165.67 99.91 164.39 98.63C163.11 97.35 161.02 97.35 159.74 98.63H159.75Z"
        fill="currentColor"
      />
      <path
        d="M3.33001 152.23C4.17001 152.23 5.01001 151.91 5.65001 151.27L38.62 118.3C39.9 117.02 39.9 114.93 38.62 113.65C37.34 112.37 35.25 112.37 33.97 113.65L1.00001 146.61C-0.27999 147.89 -0.27999 149.98 1.00001 151.26C1.64001 151.9 2.48001 152.22 3.32001 152.22L3.33001 152.23Z"
        fill="currentColor"
      />
      <path
        d="M139.06 119.32L106.17 152.21C104.89 153.49 104.89 155.58 106.17 156.86C106.81 157.5 107.65 157.82 108.49 157.82C109.33 157.82 110.17 157.5 110.81 156.86L143.7 123.97C144.98 122.69 144.98 120.6 143.7 119.32C142.42 118.04 140.33 118.04 139.05 119.32H139.06Z"
        fill="currentColor"
      />
      <path
        d="M15.08 164.38L0.97001 178.49C-0.30999 179.77 -0.30999 181.86 0.97001 183.14C1.61001 183.78 2.45001 184.1 3.29001 184.1C4.13001 184.1 4.97001 183.78 5.61001 183.14L19.72 169.03C21 167.75 21 165.66 19.72 164.38C18.44 163.1 16.35 163.1 15.07 164.38H15.08Z"
        fill="currentColor"
      />
      <path
        d="M104.25 132.48C102.96 131.2 100.88 131.2 99.6 132.48L66.78 165.4C65.5 166.69 65.5 168.77 66.78 170.05C67.42 170.69 68.26 171.01 69.1 171.01C69.94 171.01 70.79 170.69 71.43 170.04L104.25 137.12C105.53 135.83 105.53 133.75 104.25 132.47V132.48Z"
        fill="currentColor"
      />
      <path
        d="M105.22 46.03L108.77 36.43L118.37 32.88L108.77 29.33L105.22 19.73L101.67 29.33L92.07 32.88L101.67 36.43L105.22 46.03Z"
        fill="currentColor"
      />
      <path
        d="M177.55 78.91L175.78 83.71L170.98 85.48L175.78 87.26L177.55 92.06L179.33 87.26L184.13 85.48L179.33 83.71L177.55 78.91Z"
        fill="currentColor"
      />
      <path
        d="M39.46 164.44L36.8 171.64L29.6 174.31L36.8 176.97L39.46 184.17L42.13 176.97L49.33 174.31L42.13 171.64L39.46 164.44Z"
        fill="currentColor"
      />
      <path
        d="M171.29 42.81C173.107 42.81 174.58 41.337 174.58 39.52C174.58 37.703 173.107 36.23 171.29 36.23C169.473 36.23 168 37.703 168 39.52C168 41.337 169.473 42.81 171.29 42.81Z"
        fill="currentColor"
      />
    </svg>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <button
      id="theme-toggle"
      type="button"
      phx-update="ignore"
      phx-hook="ThemeToggle"
      class="size-8 flex items-center justify-center rounded-md p-1 text-gray-900 hover:bg-alpha-4"
      aria-label="Toggle dark/light mode"
    >
      <.icon
        id="theme-toggle-dark-icon"
        name="hero-moon-solid"
        class="size-6 hidden text-transparent"
      />
      <.icon id="theme-toggle-light-icon" name="hero-sun-solid" class="size-6 text-transparent" />
    </button>
    """
  end

  attr :id, :string, required: true
  attr :trigger_click, JS, default: %JS{}
  attr :trigger_click_away, JS, default: %JS{}
  slot :trigger, required: true
  slot :inner_block, required: true

  def dropdown(assigns) do
    ~H"""
    <div class="relative" phx-click-away={@trigger_click_away |> hide("##{@id}-dropdown")}>
      <div>
        <button phx-click={@trigger_click |> toggle("##{@id}-dropdown")}>
          {render_slot(@trigger)}
        </button>
      </div>
      <div id={"#{@id}-dropdown"} class="absolute z-10 hidden">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  def terraform_status(assigns) do
    color =
      case assigns.plan.status do
        :applied -> "bg-green-200 text-green-800"
        :planned -> "bg-yellow-400 text-yellow-900"
        :running -> "bg-yellow-400 text-yellow-900"
        :queued -> "bg-blue-200 text-blue-800"
        :failed -> "bg-red-200 text-red-800"
        _status -> "bg-alpha-16 text-gray-800"
      end

    plan_summary = Devhub.TerraDesk.plan_summary(assigns.plan)

    assigns = assign(assigns, color: color, plan_summary: plan_summary)

    ~H"""
    <div class="flex items-center gap-x-4">
      <p :if={@plan_summary} class="text-sm text-gray-50">
        <span class="text-green-500">+{@plan_summary.add}</span>
        <span class="text-blue-600">~{@plan_summary.change}</span>
        <span class="text-red-500">-{@plan_summary.destroy}</span>
      </p>
      <span class={"#{@color} inline-flex items-center rounded px-2 py-1 text-xs"}>
        {String.capitalize(to_string(@plan.status))}
      </span>
    </div>
    """
  end

  attr :class, :string, default: nil

  def spinner(assigns) do
    ~H"""
    <svg
      data-testid="spinner"
      class="mr-3 -ml-1 h-full w-full animate-spin"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
      </circle>
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      >
      </path>
    </svg>
    """
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :title, :string, default: nil
  attr :size, :string, default: "lg"
  slot :inner_block, required: true

  def modal(assigns) do
    size_class =
      case assigns.size do
        "large" -> "sm:max-w-4xl"
        "medium" -> "sm:max-w-2xl"
        _default -> "sm:max-w-lg"
      end

    assigns = assign(assigns, size_class: size_class)

    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="absolute z-50 hidden"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div class="fixed inset-0 bg-gray-100 opacity-90 transition-opacity" aria-hidden="true"></div>

      <div class="fixed inset-0 z-10 w-screen overflow-y-auto">
        <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <div class={[
            "bg-surface-4 relative transform rounded-lg text-left shadow-xl transition-all sm:my-8 sm:w-full",
            @size_class
          ]}>
            <button
              class="absolute top-1 right-1 focus:outline-none"
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
            >
              <.icon name="hero-x-mark-mini" class="size-5 text-alpha-64" />
            </button>
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="p-6"
            >
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={((is_map(msg) and Map.has_key?(msg, :id)) && msg.id) || @id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="bg-surface-2 pointer-events-auto w-full max-w-sm overflow-hidden rounded-lg shadow-lg ring-1 ring-gray-100 ring-opacity-5"
      {@rest}
    >
      <div class="p-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <.icon :if={@kind == :info} name="hero-check-circle-mini text-green-400" class="size-6" />
            <.icon
              :if={@kind == :error}
              name="hero-exclamation-circle-mini text-red-400"
              class="size-6"
            />
          </div>
          <div class="ml-3 w-0 flex-1 pt-0.5">
            <p class="text-sm font-medium text-gray-900">{@title}</p>
            <p class="mt-1 text-sm text-gray-500">
              {((is_map(msg) and Map.has_key?(msg, :message)) && msg.message) || msg}
            </p>
          </div>
          <div class="ml-4 flex flex-shrink-0">
            <button
              type="button"
              class="bg-alpha-4 inline-flex rounded-md text-gray-600 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              <span class="sr-only">Close</span>
              <svg
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
                data-slot="icon"
              >
                <path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 1 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22Z" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div class="flex w-full flex-col items-center space-y-4 sm:items-end" id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-8 bg-gray-900">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :tooltip, :string, default: nil
  attr :tooltip_position, :string, default: "right"

  attr :type, :string,
    default: "text",
    values: ~w(toggle checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "toggle"} = assigns) do
    color = if assigns[:value] == true, do: "bg-blue-300", else: "bg-alpha-24"

    assigns =
      assigns
      |> assign_new(:checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)
      |> assign(color: color)

    ~H"""
    <div class={"#{@rest[:disabled] && "opacity-50"} group"}>
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        class="hidden"
        {@rest}
      />
      <div class="flex items-center">
        <button
          type="button"
          class="group relative inline-flex h-5 w-10 flex-shrink-0 cursor-pointer items-center justify-center rounded-full focus:outline-none"
          role="switch"
          aria-checked="false"
          phx-click={JS.dispatch("click", to: "##{@id}")}
        >
          <span aria-hidden="true" class="pointer-events-none absolute h-full w-full rounded-md">
          </span>
          <span
            aria-hidden="true"
            class={[
              "pointer-events-none absolute mx-auto h-4 w-9 rounded-full transition-colors duration-200 ease-in-out group-focus:ring-1 group-focus:ring-blue-700",
              @color
            ]}
          >
          </span>
          <span
            aria-hidden="true"
            class={[
              "pointer-events-none absolute left-0 inline-block h-5 w-5 transform rounded-full border border-gray-200 bg-white shadow ring-0 transition-transform duration-200 ease-in-out",
              (@checked && "translate-x-5") || "translate-x-0"
            ]}
          >
          </span>
        </button>
        <span class="ml-3 flex items-center gap-x-1 text-sm">
          <span class="text-alpha-64 block text-xs uppercase">{@label}</span>
          <div :if={@tooltip} class={"tooltip-#{@tooltip_position} tooltip"}>
            <span class="bg-alpha-16 text-alpha-64 size-4 relative flex items-center justify-center rounded-full text-xs">
              ?
            </span>
            <span class="tooltiptext w-64 p-2">{@tooltip}</span>
          </div>
        </span>
      </div>
    </div>
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class={"#{@rest[:disabled] && "opacity-50"}"}>
      <label class="text-alpha-64 flex items-center gap-2 text-xs uppercase">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="ring-alpha-16 bg-alpha-4 rounded border-none accent-gray-900 ring-1"
          {@rest}
        />

        <div class="flex items-center gap-x-1">
          {@label}
          <div :if={@tooltip} class={"tooltip-#{@tooltip_position} tooltip"}>
            <span class="bg-alpha-16 text-alpha-64 size-4 relative flex items-center justify-center rounded-full text-xs">
              ?
            </span>
            <span class="tooltiptext w-64 p-2">{@tooltip}</span>
          </div>
        </div>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    options =
      assigns[:options] &&
        Enum.map(assigns.options, fn
          {key, value} -> [key: key, value: value, class: "bg-surface-3 text-gray-900"]
          key -> [key: key, value: key, class: "bg-surface-3 text-gray-900"]
        end)

    assigns = assign(assigns, options: options)

    ~H"""
    <div>
      <.label :if={@label} for={@id} tooltip={@tooltip} tooltip_position={@tooltip_position}>
        {@label}
      </.label>
      <div class="relative mt-2">
        <select
          id={@id}
          name={@name}
          class={[
            "bg-alpha-4 text-alpha-88 w-full rounded py-2.5 text-sm",
            "ring-1 ring-inset focus:ring-1 focus:ring-inset",
            "border-none focus:border-none",
            @errors == [] && "ring-alpha-16 focus:ring-blue-700",
            @errors != [] && "ring-red-400 focus:ring-red-400"
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {@options && Phoenix.HTML.Form.options_for_select(@options, @value)}
          {render_slot(@inner_block)}
        </select>
        <div class="z-5 pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 py-2.5 focus:outline-none">
          <.icon name="hero-chevron-up-down" class="h-5 w-5 text-gray-400" />
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id} tooltip={@tooltip} tooltip_position={@tooltip_position}>
        {@label}
      </.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "bg-alpha-4 mt-2 block w-full rounded text-sm focus:ring-0",
          "min-h-[6rem] border-alpha-16 focus:border-blue-700",
          @errors == [] && "ring-alpha-16 focus-within:ring-blue-700",
          @errors != [] && "border-red-400 focus:border-red-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      id={@id}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      {@rest}
    />
    """
  end

  def input(%{type: "color"} = assigns) do
    ~H"""
    <div class="-mb-1 cursor-pointer">
      <.label :if={@label} for={@id} tooltip={@tooltip} tooltip_position={@tooltip_position}>
        {@label}
      </.label>
      <input
        type="color"
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class="-mt-[0.25rem] -mx-[0.125rem] w-[calc(100%+0.25rem)] h-10 cursor-pointer border-none bg-transparent p-0"
        {@rest}
      />
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label :if={@label} for={@id} tooltip={@tooltip} tooltip_position={@tooltip_position}>
        {@label}
      </.label>
      <div class="mt-2">
        <div class={[
          "bg-alpha-4 flex w-full rounded px-2 py-1 ring-1 ring-inset",
          @errors == [] && "ring-alpha-16 focus-within:ring-blue-700",
          @errors != [] && "ring-red-400 focus-within:ring-red-400"
        ]}>
          <input
            type={@type}
            name={@name}
            id={@id}
            value={Phoenix.HTML.Form.normalize_value(@type, @value)}
            class={[
              "text-alpha-88 max-w-full flex-1 border-0 bg-transparent py-1.5 pl-1 text-sm placeholder:text-alpha-64 focus:ring-0 disabled:opacity-50"
            ]}
            {@rest}
          />
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :tooltip, :string, default: nil
  attr :tooltip_position, :string, default: "right"
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <div class="mb-2 flex items-center gap-x-1">
      <label for={@for} class="text-alpha-64 block text-xs uppercase">
        {render_slot(@inner_block)}
      </label>
      <div :if={@tooltip} class={"tooltip-#{@tooltip_position} tooltip"}>
        <span class="bg-alpha-16 text-alpha-64 size-4 relative flex items-center justify-center rounded-full text-xs">
          ?
        </span>
        <span class="tooltiptext w-64 p-2">{@tooltip}</span>
      </div>
    </div>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-2 flex gap-2 text-sm text-red-400">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-medium text-zinc-800">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm text-zinc-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :phx_viewport_top, :string, default: nil
  attr :phx_viewport_bottom, :string, default: nil
  attr :tbody_class, :string, default: nil

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0" id={@id}>
      <table class="mt-2 w-full table-fixed text-sm ">
        <thead class="text-left text-gray-500">
          <tr>
            <th :for={col <- @col} class={["p-0 px-2 pb-2 font-normal", col[:class]]}>
              {col[:label]}
            </th>
            <th :if={@action != []} class="w-[4%]">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id <> "-tbody"}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          phx-viewport-top={@phx_viewport_top}
          phx-viewport-bottom={@phx_viewport_bottom}
          phx-page-loading
          class={[
            "divide-alpha-16 border-alpha-16 relative divide-y border-t text-sm text-gray-700",
            @tbody_class
          ]}
          @rest
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-alpha-4">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0 px-2", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4">
                <span class="absolute -inset-y-px right-0 -left-4" />
                <span class={["relative", i == 0 && "font-medium text-gray-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []}>
              <span :for={action <- @action}>
                {render_slot(action, @row_item.(row))}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <.link navigate={@navigate} class="text-sm font-medium text-blue-500 hover:text-blue-400">
      <.icon name="hero-arrow-left-solid" class="h-3 w-3" /> {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :id, :string, default: nil
  attr :name, :string, required: true
  attr :class, :any, default: nil

  def icon(assigns) do
    ~H"""
    <span id={@id} class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def toggle(js \\ %JS{}, selector) do
    JS.toggle(js,
      to: selector,
      time: 200,
      in:
        {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"},
      out:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def toggle_slide(js \\ %JS{}, selector) do
    JS.toggle(js,
      to: selector,
      time: 200,
      in: {"transition-all transform slide duration-300", "opacity-0 translate-x-12", "opacity-100 translate-x-0"},
      out: {"transition-all transform ease-in duration-200", "opacity-100 translate-x-0", "opacity-0 translate-x-12"}
    )
  end

  def slide_out(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-x-0", "opacity-0 translate-x-12"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: ".focus-on-show")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(DevhubWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(DevhubWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
