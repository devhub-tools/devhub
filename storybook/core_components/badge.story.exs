defmodule Storybook.Components.CoreComponents.Badge do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DevhubWeb.Components.Badge.badge/1
  def render_source, do: :function

  def template do
    """
    <div class="py-2" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :coverage,
        variations: [
          %Variation{
            id: :xs_blue,
            attributes: %{
              label: "Managed",
              color: "blue",
              size: "xs"
            }
          },
          %Variation{
            id: :sm_blue,
            attributes: %{
              label: "Managed",
              color: "blue",
              size: "sm"
            }
          },
          %Variation{
            id: :default_blue,
            attributes: %{
              label: "Managed",
              color: "blue"
            }
          },
          %Variation{
            id: :xs_gray,
            attributes: %{
              label: "Managed",
              color: "gray",
              size: "xs"
            }
          },
          %Variation{
            id: :sm_gray,
            attributes: %{
              label: "Managed",
              color: "gray",
              size: "sm"
            }
          },
          %Variation{
            id: :default_gray,
            attributes: %{
              label: "Managed",
              color: "gray"
            }
          }
        ]
      }
    ]
  end
end
