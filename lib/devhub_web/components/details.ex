defmodule DevhubWeb.Components.Details do
  @moduledoc false
  use DevhubWeb, :html

  attr :id, :string, required: true
  attr :class, :string, default: nil

  slot :summary, required: true
  slot :inner_block, required: true

  def details(assigns) do
    ~H"""
    <div class={@class}>
      <button type="button" phx-click={toggle("##{@id}-details")} class="w-full">
        {render_slot(@summary)}
      </button>
      <div id={"#{@id}-details"} class="hidden text-left">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
