defmodule Storybook.Components.CoreComponents.Logo do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DevhubWeb.CoreComponents.logo/1
  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :logo,
        attributes: %{}
      }
    ]
  end
end
