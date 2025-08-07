defmodule DevhubWeb.Components.Button do
  @moduledoc false
  use DevhubWeb, :html

  attr :type, :string, default: nil
  attr :class, :string, default: nil

  attr :variant, :string,
    values: ~w(primary secondary text),
    default: "primary",
    doc: "the button variant style"

  attr :size, :string, values: ~w(default sm lg icon), default: "default"
  attr :rest, :global, include: ~w(disabled form name value data-testid)

  slot :inner_block, required: true

  def button(assigns) do
    assigns = assign(assigns, variant_class: variant(assigns))

    ~H"""
    <button
      type={@type}
      class={[
        "inline-flex cursor-pointer items-center justify-center whitespace-nowrap rounded-md transition-colors disabled:pointer-events-none disabled:opacity-50",
        focus_class(),
        @variant_class,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil

  attr :variant, :string,
    values: ~w(primary secondary neutral destructive outline destructive-text),
    default: "primary",
    doc: "the button variant style"

  attr :size, :string, values: ~w(default sm lg icon), default: "default"
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def link_button(assigns) do
    assigns = assign(assigns, variant_class: variant(assigns))

    ~H"""
    <.link
      class={[
        "inline-flex cursor-pointer items-center justify-center whitespace-nowrap rounded-md transition-colors disabled:pointer-events-none disabled:opacity-50",
        focus_class(),
        @variant_class,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @variants %{
    variant: %{
      "primary" => "p-2 bg-blue-300 hover:bg-blue-400 text-white",
      "neutral" => "p-2 bg-alpha-24 hover:bg-gray-500 text-gray-900",
      "secondary" => "p-2 text-gray-900 ring-1 ring-gray-400 hover:ring-gray-900 ring-inset",
      "destructive" => "p-2 bg-red-200 hover:bg-red-300 text-red-800",
      "outline" => "p-2 text-blue-800 hover:text-blue-700 ring-1 ring-blue-300 hover:ring-blue-400 ring-inset",
      "text" => "text-blue-800",
      "destructive-text" => "text-red-400"
    },
    size: %{
      "default" => "h-8 text-sm font-bold",
      "sm" => "h-6 text-sm"
    }
  }

  @default_variants %{
    variant: "default",
    size: "default"
  }

  defp variant(props) do
    variants = Map.take(props, ~w(variant size)a)
    variants = Map.merge(@default_variants, variants)

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end
end
