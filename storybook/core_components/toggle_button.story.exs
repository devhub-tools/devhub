defmodule Storybook.Components.CoreComponents.ToggleButton do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DevhubWeb.Components.ToggleButton.toggle_button/1
  def render_source, do: :function

  def template do
    """
    <div class="py-6" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          "phx-click": "toggle_action",
          "phx-value-id": "1",
          enabled: true
        }
      },
      %Variation{
        id: :disabled,
        attributes: %{
          enabled: false
        }
      }
    ]
  end
end
