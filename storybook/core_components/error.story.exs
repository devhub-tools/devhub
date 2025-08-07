defmodule Storybook.Components.CoreComponents.Error do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DevhubWeb.CoreComponents.error/1
  def imports, do: [{DevhubWeb.CoreComponents, button: 1}]

  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :default,
        description: "Typical error message",
        slots: [
          """
          Something went wrong ...
          """
        ]
      },
      %Variation{
        id: :try_again,
        slots: [
          """
          Something went wrong ...
          <div class="mt-2">
            <.button>Try again</.button>
          </div>
          """
        ]
      }
    ]
  end
end
