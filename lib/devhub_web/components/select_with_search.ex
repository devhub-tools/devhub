defmodule DevhubWeb.Components.SelectWithSearch do
  @moduledoc false
  use DevhubWeb, :html

  attr :id, :string, required: true
  attr :selected, :string, default: nil
  attr :form, :map, required: true
  attr :field, :atom, required: true
  slot :item

  def select_with_search(assigns) do
    search = assigns.form[assigns.search_field].value

    objects = if is_nil(search), do: [], else: assigns.search_fun.(String.downcase(search))

    assigns = assign(assigns, objects: objects, search: search)

    ~H"""
    <div
      id={"#{@id}-container"}
      class="relative w-full"
      phx-key="tab"
      phx-window-keyup={hide("##{@id}-options")}
    >
      <div>
        <div class="relative" phx-click={show("##{@id}-options")}>
          <.input field={@form[@field]} type="hidden" />
          <.input
            aria-controls={"#{@id}-options"}
            aria-expanded="false"
            autocomplete="off"
            field={@form[@search_field]}
            role="combobox"
            type="text"
            label={@label}
            value={@search || @selected}
          />
          <div class="absolute right-0 bottom-2.5 flex items-center px-2 focus:outline-none">
            <.icon id={"#{@id}-icon"} name="hero-chevron-up-down" class="h-5 w-5 text-gray-400" />
          </div>
        </div>
      </div>

      <div
        id={"#{@id}-options"}
        phx-click-away={hide("##{@id}-options")}
        phx-key="escape"
        phx-window-keyup={hide("##{@id}-options")}
        class="hidden"
      >
        <ul
          :if={not Enum.empty?(@objects)}
          class="bg-surface-3 absolute z-10 mt-1 max-h-56 w-full overflow-auto rounded py-1 ring-1 ring-gray-100 ring-opacity-5 focus:outline-none sm:text-sm"
          role="listbox"
        >
          <li
            :for={object <- @objects}
            class="relative cursor-pointer select-none py-2 pr-9 pl-4 hover:bg-blue-100 focus:bg-blue-100"
            phx-click={
              hide("##{@id}-options")
              |> JS.set_attribute({"value", object.id}, to: "##{@form[@field].id}")
              |> JS.set_attribute({"value", object.name}, to: "##{@form[@search_field].id}")
              |> JS.dispatch("input", to: "##{@form[@field].id}")
            }
            phx-key="enter"
            phx-keydown={
              hide("##{@id}-options")
              |> JS.set_attribute({"value", object.id}, to: "##{@form[@field].id}")
              |> JS.set_attribute({"value", object.name}, to: "##{@form[@search_field].id}")
              |> JS.dispatch("input", to: "##{@form[@field].id}")
            }
            role="option"
            tabindex="-1"
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
    </div>
    """
  end
end
