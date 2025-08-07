defmodule DevhubWeb.Components.PageHeader do
  @moduledoc false
  use Phoenix.Component

  attr :class, :string, default: ""
  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  slot :header
  slot :actions

  def page_header(assigns) do
    ~H"""
    <div class="bg-surface-0 sticky top-0 z-20 -mt-4 py-4">
      <div class={["bg-surface-1 flex items-center justify-between gap-x-4 rounded-lg p-4", @class]}>
        <div :if={@title} class="flex min-w-0 gap-x-4">
          <div class="min-w-0 flex-auto">
            <p class="text-2xl font-bold">
              {@title}
            </p>
            <p :if={@subtitle} class="mt-1 flex text-xs text-gray-600">
              {@subtitle}
            </p>
          </div>
        </div>
        {render_slot(@header)}
        <div class="flex items-center gap-x-4">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end
end
