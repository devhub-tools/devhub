defmodule DevhubWeb.Components.Tabs do
  @moduledoc false

  use DevhubWeb, :html

  attr :tabs, :list, required: true

  def tabs(assigns) do
    ~H"""
    <nav class="flex gap-x-4">
      <.tab
        :for={tab <- @tabs}
        hide={Map.get(tab, :hide, false)}
        active_path={@active_path}
        link={tab.link}
        icon={tab.icon}
        title={tab.title}
      />
    </nav>
    """
  end

  defp tab(assigns) do
    ~H"""
    <div :if={not @hide}>
      <.link
        navigate={@link}
        class={[
          "group text-sm/6 flex gap-x-2 rounded-md p-2 font-semibold hover:bg-alpha-8",
          (@active_path == @link && "bg-blue-100 text-blue-700") || "text-alpha-64"
        ]}
      >
        <.icon name={@icon} class="size-6 shrink-0" /> {@title}
      </.link>
    </div>
    """
  end
end
