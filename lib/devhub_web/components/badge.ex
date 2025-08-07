defmodule DevhubWeb.Components.Badge do
  @moduledoc false
  use DevhubWeb, :html

  attr :color, :string,
    values: ~w(blue gray),
    default: "gray",
    doc: "the badge color"

  attr :size, :string, values: ~w(default sm xs), default: "default"

  def badge(assigns) do
    assigns = assign(assigns, variant_class: variant(assigns))

    ~H"""
    <div class={[@variant_class, "rounded-md border text-sm"]}>
      {@label}
    </div>
    """
  end

  @variants %{
    color: %{
      "blue" => "border-blue-600/20 bg-blue-600/10 text-blue-600",
      "gray" => "border-gray-600/20 bg-gray-600/10 text-gray-600",
      "green" => "border-green-600/20 bg-green-600/10 text-green-600",
      "red" => "border-red-600/20 bg-red-600/10 text-red-600"
    },
    size: %{
      "default" => "px-2 py-0.5",
      "sm" => "px-1 py-0.5",
      "xs" => "px-1 py-0.5 text-xs"
    }
  }

  @default_variants %{
    color: "default",
    size: "default"
  }

  defp variant(props) do
    variants = Map.take(props, ~w(color size)a)
    variants = Map.merge(@default_variants, variants)

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end
end
