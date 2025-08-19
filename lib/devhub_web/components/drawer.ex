defmodule DevhubWeb.Components.Drawer do
  @moduledoc false
  use DevhubWeb, :html

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :width, :string, default: "w-96"

  slot :trigger
  slot :inner_block, required: true

  def drawer(assigns) do
    ~H"""
    <div id={@id}>
      <div :if={not Enum.empty?(@trigger)}>
        <button type="button" phx-click={toggle_slide("##{@id}-content")} class={@class}>
          {render_slot(@trigger)}
        </button>
      </div>
      <div
        id={"#{@id}-content"}
        phx-click-away={slide_out("##{@id}-content")}
        class={["bg-surface-2 fixed inset-y-0 right-0 z-30 hidden overflow-y-auto p-4", @width]}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
