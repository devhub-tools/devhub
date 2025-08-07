defmodule Storybook.Components.CoreComponents.LinkButton do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DevhubWeb.Components.Button.link_button/1
  def render_source, do: :function

  def variations do
    [
      %VariationGroup{
        id: :variants,
        variations: [
          %Variation{
            id: :primary,
            attributes: %{
              variant: "primary",
              navigate: "/storybook"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :secondary,
            attributes: %{
              variant: "secondary",
              navigate: "/storybook"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :neutral,
            attributes: %{
              variant: "neutral",
              navigate: "/storybook"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :destructive,
            attributes: %{
              variant: "destructive",
              navigate: "/storybook"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :outline,
            attributes: %{
              variant: "outline",
              navigate: "/storybook"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :text,
            attributes: %{
              variant: "text",
              navigate: "/storybook"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :destructive_text,
            attributes: %{
              variant: "destructive-text",
              navigate: "/storybook"
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
              size: "sm",
              navigate: "/storybook"
            },
            slots: [
              "Click me!"
            ]
          },
          %Variation{
            id: :large,
            attributes: %{
              size: "lg",
              navigate: "/storybook"
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
          disabled: true,
          navigate: "/storybook"
        },
        slots: [
          "Click me!"
        ]
      }
    ]
  end
end
