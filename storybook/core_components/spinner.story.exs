defmodule Storybook.Components.CoreComponents.Spinner do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DevhubWeb.CoreComponents.spinner/1
  def render_source, do: :function

  def variations do
    [
      %Variation{
        id: :spinner,
        attributes: %{}
      }
    ]
  end
end
