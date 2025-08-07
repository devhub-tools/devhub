defmodule DevhubWeb.Components.MultiSelect do
  @moduledoc false
  use DevhubWeb, :html

  attr :filtered_objects, :list, required: true
  attr :selected_objects, :string, required: true
  attr :select_action, :string, required: true
  attr :filter_action, :string, required: true
  slot :item

  def multi_select(assigns) do
    placeholder =
      case assigns.selected_objects do
        [] -> assigns.placeholder
        [extension] -> extension
        extensions -> "#{length(extensions)} extensions"
      end

    assigns = assign(assigns, form: to_form(%{"name" => ""}), placeholder: placeholder)

    ~H"""
    <div
      id={"#{@select_action}-container"}
      class="relative w-full"
      phx-key="tab"
      phx-window-keyup={hide_search(@select_action) |> JS.push("clear_filter")}
    >
      <div id={"#{@select_action}-selection"} class="relative" phx-click={show_search(@select_action)}>
        <.input type="text" name="_unused_selected" value={@placeholder} />
        <div class="absolute inset-y-0 right-0 flex items-center px-2 focus:outline-none">
          <.icon
            id={"#{@select_action}-icon"}
            name="hero-chevron-up-down"
            class="h-5 w-5 text-gray-400"
          />
        </div>
      </div>
      <div class="relative hidden" id={"#{@select_action}-search"}>
        <.input
          id={@select_action <> "-search"}
          aria-controls={"#{@select_action}-options"}
          aria-expanded="false"
          autocomplete="off"
          field={@form[:name]}
          phx-change={@filter_action}
          phx-value-action={@select_action}
          role="combobox"
          type="text"
        />
        <div class="absolute inset-y-0 right-0 flex items-center px-2 focus:outline-none">
          <.icon
            id={"#{@select_action}-icon"}
            name="hero-chevron-up-down"
            class="h-5 w-5 text-gray-400"
          />
        </div>
      </div>

      <ul
        id={"#{@select_action}-options"}
        class="bg-surface-3 absolute z-10 mt-1 hidden max-h-56 w-full overflow-auto rounded py-1 ring-1 ring-gray-100 ring-opacity-5 focus:outline-none sm:text-sm"
        phx-click-away={hide_search(@select_action) |> JS.push("clear_filter")}
        phx-key="escape"
        phx-window-keyup={hide_search(@select_action) |> JS.push("clear_filter")}
        role="listbox"
      >
        <li class="flex cursor-pointer select-none items-center justify-between px-3 py-2 hover:bg-blue-100 focus:bg-blue-100">
          <button type="button" phx-click="select_all">
            All extensions
          </button>
          <.icon :if={Enum.empty?(@selected_objects)} name="hero-check" class="size-4 text-blue-600" />
        </li>
        <li
          :for={object <- @filtered_objects}
          class="relative cursor-pointer select-none px-3 py-2 hover:bg-blue-100 focus:bg-blue-100"
          phx-click={@select_action}
          phx-key="enter"
          phx-keydown={@select_action}
          phx-value-id={object}
          role="option"
          tabindex="-1"
        >
          <div class="flex items-center justify-between">
            <%= if @item != [] do %>
              {render_slot(@item, object)}
            <% else %>
              <p>{object}</p>
            <% end %>
            <.icon :if={object in @selected_objects} name="hero-check" class="size-4 text-blue-600" />
          </div>
        </li>
      </ul>
    </div>
    """
  end

  defp show_search(js \\ %JS{}, select_action) do
    js
    |> JS.show(to: "##{select_action}-options")
    |> JS.show(to: "##{select_action}-search")
    |> JS.hide(to: "##{select_action}-selection")
    |> JS.focus(to: "##{select_action}-search")
  end

  defp hide_search(js \\ %JS{}, select_action) do
    js
    |> JS.hide(to: "##{select_action}-options")
    |> JS.hide(to: "##{select_action}-search")
    |> JS.show(to: "##{select_action}-selection")
  end
end
