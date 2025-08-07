defmodule DevhubWeb.Components.DropdownWithSearch do
  @moduledoc false
  use DevhubWeb, :html

  attr :filtered_objects, :list, required: true
  attr :filter_action, :string, required: true

  attr :friendly_action_name, :string,
    required: false,
    doc: "Populates an Arial label for the search input. If not provided, the value is derived from select_action."

  attr :selected_object_name, :string, required: true
  attr :select_action, :string, required: true
  attr :select_value, :map, default: %{}
  slot :item
  attr :rest, :global, include: ~w(phx-target)

  def dropdown_with_search(assigns) do
    assigns =
      assigns
      |> assign(:form, to_form(%{"name" => assigns.selected_object_name}))
      |> derive_friendly_action_name()

    ~H"""
    <div
      id={"#{@select_action}-container"}
      class="relative w-full"
      phx-key="tab"
      phx-window-keyup={hide("##{@select_action}-options") |> JS.push("clear_filter")}
      {@rest}
    >
      <div>
        <.form :let={f} for={@form} id={@select_action <> "-form"} class="overflow-hidden">
          <div class="relative" phx-click={show("##{@select_action}-options")}>
            <.input
              id={@select_action <> "-search"}
              aria-controls={"#{@select_action}-options"}
              aria-expanded="false"
              aria-label={@friendly_action_name}
              autocomplete="off"
              field={f[:name]}
              phx-change={show("##{@select_action}-options") |> JS.push(@filter_action)}
              phx-hook="SelectNavigation"
              phx-value-action={@select_action}
              role="combobox"
              type="text"
              {@rest}
            />
            <div class="absolute inset-y-0 right-0 flex items-center px-2 focus:outline-none">
              <.icon
                id={"#{@select_action}-icon"}
                name="hero-chevron-up-down"
                class="h-5 w-5 text-gray-400"
              />
            </div>
          </div>
        </.form>
      </div>

      <ul
        id={"#{@select_action}-options"}
        class="bg-surface-3 absolute z-10 mt-1 hidden max-h-56 w-full overflow-auto rounded py-1 ring-1 ring-gray-100 ring-opacity-5 focus:outline-none sm:text-sm"
        phx-click-away={hide("##{@select_action}-options") |> JS.push("clear_filter")}
        phx-key="escape"
        phx-window-keyup={hide("##{@select_action}-options") |> JS.push("clear_filter")}
        role="listbox"
        {@rest}
      >
        <li
          :for={object <- @filtered_objects}
          class="relative cursor-pointer select-none px-3 py-2 hover:bg-blue-100 focus:bg-blue-100"
          phx-click={
            hide("##{@select_action}-options") |> JS.push(@select_action, value: @select_value)
          }
          phx-key="enter"
          phx-keydown={
            hide("##{@select_action}-options") |> JS.push(@select_action, value: @select_value)
          }
          phx-value-id={object.id}
          role="option"
          tabindex="-1"
          {@rest}
        >
          <div class="flex items-center">
            <%= if @item != [] do %>
              {render_slot(@item, object)}
            <% else %>
              <p>{object.name}</p>
            <% end %>
          </div>
        </li>
      </ul>
    </div>
    """
  end

  # If you pass in Friendly Action Name, we'll use that. Otherwise, we'll determine it from the action name.
  defp derive_friendly_action_name(%{friendly_action_name: friendly_action_name} = assigns)
       when is_binary(friendly_action_name) do
    assigns
  end

  defp derive_friendly_action_name(assigns) do
    [head | rest] = String.split(assigns.select_action, "_")

    head = String.capitalize(head)
    name = Enum.join([head | rest], " ") <> " " <> "search"

    assign(assigns, :friendly_action_name, name)
  end
end
