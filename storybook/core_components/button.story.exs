defmodule Storybook.Components.CoreComponents.Button do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DevhubWeb.Components.Button.button/1
  def render_source, do: :function

  def variations do
    [
      %VariationGroup{
        id: :variants,
        variations: [
          %Variation{
            id: :primary,
            attributes: %{
              type: "button",
              variant: "primary"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :secondary,
            attributes: %{
              type: "button",
              variant: "secondary"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :text,
            attributes: %{
              type: "button",
              variant: "text"
            },
            slots: [
              "Click me!"
            ]
          }
        ]
      },
      %VariationGroup{
        id: :sizes,
        variations: [
          %Variation{
            id: :small,
            attributes: %{
              type: "button",
              size: "sm"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :large,
            attributes: %{
              type: "button",
              size: "lg"
            },
            slots: [
              "Click me!"
            ]
          }
        ]
      },
      %Variation{
        id: :disabled,
        attributes: %{
          type: "button",
          disabled: true
        },
        slots: [
          "Click me!"
        ]
      }
    ]
  end
end
