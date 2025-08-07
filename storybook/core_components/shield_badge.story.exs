defmodule Storybook.Components.CoreComponents.ShieldBadge do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DevhubWeb.Components.ShieldBadge.shield_badge/1
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
            id: :low,
            attributes: %{
              type: :coverage,
              percentage: 10
            }
          },
          %Variation{
            id: :bad,
            attributes: %{
              type: :coverage,
              percentage: 60
            }
          },
          %Variation{
            id: :okay,
            attributes: %{
              type: :coverage,
              percentage: 70
            }
          },
          %Variation{
            id: :good,
            attributes: %{
              type: :coverage,
              percentage: 80
            }
          },
          %Variation{
            id: :great,
            attributes: %{
              type: :coverage,
              percentage: 90
            }
          },
          %Variation{
            id: :excellent,
            attributes: %{
              type: :coverage,
              percentage: 95
            }
          }
        ]
      },
      %Variation{
        id: :uptime,
        attributes: %{
          type: :uptime,
          uptime: 0.95
        }
      },
      %Variation{
        id: :latency,
        attributes: %{
          type: :latency,
          average_response_time: 95
        }
      },
      %VariationGroup{
        id: :health,
        variations: [
          %Variation{
            id: :up,
            attributes: %{
              type: :health,
              up: true
            }
          },
          %Variation{
            id: :down,
            attributes: %{
              type: :health,
              up: false
            }
          }
        ]
      }
    ]
  end
end
