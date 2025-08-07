defmodule DevhubWeb.Components.ObjectLabel do
  @moduledoc false
  use DevhubWeb, :html

  attr :label, :map, required: true
  attr :phx_click, :string, default: nil
  attr :icon, :string, default: nil
  attr :rest, :global

  def object_label(assigns) do
    ~H"""
    <div
      {@rest}
      class={[
        "ring-alpha-8 mt-1 flex w-fit items-center gap-x-1 truncate rounded-full px-2 py-1 text-xs text-gray-600 ring-1 ring-inset",
        @icon != "hero-x-mark" && "hover:bg-alpha-4"
      ]}
    >
      <div class="mr-1 h-2 w-2 rounded-full" style={"background-color:#{@label.color}"}></div>
      <div class="text-gray-600">{@label.name}</div>
      <.icon :if={@icon} name={@icon} class="size-3 text-gray-400 hover:text-gray-600" />
    </div>
    """
  end
end
