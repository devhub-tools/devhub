defmodule DevhubWeb.Components.HoverCard do
  @moduledoc false
  use DevhubWeb, :html

  @doc """
  Render hover card wrapper
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :hover_content, required: true

  def hover_card(assigns) do
    ~H"""
    <div class={["group/hover-card relative inline-block", @class]} {@rest}>
      {render_slot(@inner_block)}
      <div class={[
        "bg-surface-3 absolute mt-2 hidden w-60 group-hover/hover-card:block",
        "z-50 rounded-md p-4 shadow-md outline-none"
      ]}>
        {render_slot(@hover_content)}
      </div>
    </div>
    """
  end
end
