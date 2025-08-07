defmodule DevhubWeb.Components.ToggleButton do
  @moduledoc false
  use DevhubWeb, :html

  attr :rest, :global
  attr :enabled, :boolean

  def toggle_button(assigns) do
    ~H"""
    <button
      type="button"
      class="group relative flex inline-flex h-5 w-10 flex-shrink-0 cursor-pointer items-center justify-end rounded-full focus:outline-none"
      {@rest}
    >
      <span aria-hidden="true" class="pointer-events-none absolute h-full w-full rounded-md"></span>
      <span
        aria-hidden="true"
        class={[
          "pointer-events-none absolute mx-auto h-4 w-9 rounded-full transition-colors duration-200 ease-in-out",
          (@enabled && "bg-blue-300") || "bg-alpha-24"
        ]}
      >
      </span>
      <span
        aria-hidden="true"
        class={[
          "pointer-events-none absolute left-0 inline-block h-5 w-5 transform rounded-full border border-gray-200 bg-white shadow ring-0 transition-transform duration-200 ease-in-out",
          (@enabled && "translate-x-5") || "translate-x-0"
        ]}
      >
      </span>
    </button>
    """
  end
end
