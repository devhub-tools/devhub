defmodule Storybook.Colors do
  # See https://hexdocs.pm/phoenix_storybook/PhoenixStorybook.Story.html for full story
  # documentation.
  @moduledoc false
  use PhoenixStorybook.Story, :page

  # adding all colors so that tailwind picks them up
  # %{
  #   blue: [
  #     "bg-blue-50",
  #     "bg-blue-100",
  #     "bg-blue-200",
  #     "bg-blue-300",
  #     "bg-blue-400",
  #     "bg-blue-500",
  #     "bg-blue-600",
  #     "bg-blue-700",
  #     "bg-blue-800",
  #     "bg-blue-900"
  #   ],
  #   red: [
  #     "bg-red-50",
  #     "bg-red-100",
  #     "bg-red-200",
  #     "bg-red-300",
  #     "bg-red-400",
  #     "bg-red-500",
  #     "bg-red-600",
  #     "bg-red-700",
  #     "bg-red-800",
  #     "bg-red-900"
  #   ],
  #   green: [
  #     "bg-green-50",
  #     "bg-green-100",
  #     "bg-green-200",
  #     "bg-green-300",
  #     "bg-green-400",
  #     "bg-green-500",
  #     "bg-green-600",
  #     "bg-green-700",
  #     "bg-green-800",
  #     "bg-green-900"
  #   ],
  #   yellow: [
  #     "bg-yellow-50",
  #     "bg-yellow-100",
  #     "bg-yellow-200",
  #     "bg-yellow-300",
  #     "bg-yellow-400",
  #     "bg-yellow-500",
  #     "bg-yellow-600",
  #     "bg-yellow-700",
  #     "bg-yellow-800",
  #     "bg-yellow-900"
  #   ],
  #   orange: [
  #     "bg-orange-50",
  #     "bg-orange-100",
  #     "bg-orange-200",
  #     "bg-orange-300",
  #     "bg-orange-400",
  #     "bg-orange-500",
  #     "bg-orange-600",
  #     "bg-orange-700",
  #     "bg-orange-800",
  #     "bg-orange-900"
  #   ],
  #   purple: [
  #     "bg-purple-50",
  #     "bg-purple-100",
  #     "bg-purple-200",
  #     "bg-purple-300",
  #     "bg-purple-400",
  #     "bg-purple-500",
  #     "bg-purple-600",
  #     "bg-purple-700",
  #     "bg-purple-800",
  #     "bg-purple-900"
  #   ],
  #   pink: [
  #     "bg-pink-50",
  #     "bg-pink-100",
  #     "bg-pink-200",
  #     "bg-pink-300",
  #     "bg-pink-400",
  #     "bg-pink-500",
  #     "bg-pink-600",
  #     "bg-pink-700",
  #     "bg-pink-800",
  #     "bg-pink-900"
  #   ],
  #   gray: [
  #     "bg-gray-50",
  #     "bg-gray-100",
  #     "bg-gray-200",
  #     "bg-gray-300",
  #     "bg-gray-400",
  #     "bg-gray-500",
  #     "bg-gray-600",
  #     "bg-gray-700",
  #     "bg-gray-800",
  #     "bg-gray-900"
  #   ],
  #   surface: [
  #     "bg-surface-0",
  #     "bg-surface-1",
  #     "bg-surface-2",
  #     "bg-surface-3",
  #     "bg-surface-4"
  #   ],
  #   alpha: [
  #     "bg-alpha-4",
  #     "bg-alpha-8",
  #     "bg-alpha-16",
  #     "bg-alpha-24",
  #     "bg-alpha-32",
  #     "bg-alpha-40",
  #     "bg-alpha-64",
  #     "bg-alpha-72",
  #     "bg-alpha-80",
  #     "bg-alpha-88"
  #   ]
  # }

  def render(assigns) do
    ~H"""
    <div :for={theme <- ["light", "dark"]} class={"#{theme} bg-surface-0 mb-8 rounded-lg p-8"}>
      <div class="flex flex-col gap-4">
        <div class="flex gap-4">
          <div class="w-16"></div>
          <div :for={shade <- ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900"]}>
            <div class="flex h-8 w-16 items-center justify-center text-sm font-medium text-gray-600">
              {shade}
            </div>
          </div>
        </div>
        <div :for={color <- ["blue", "red", "green", "yellow", "orange", "purple", "pink", "gray"]}>
          <div class="flex gap-4">
            <div class="flex h-16 w-16 items-center justify-center text-sm font-medium text-gray-600">
              {color}
            </div>
            <div :for={shade <- ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900"]}>
              <% color = "bg-#{color}-#{shade}" %>
              <div class={"#{color} h-16 w-16 rounded"}></div>
            </div>
          </div>
        </div>
        
    <!-- Surface Colors -->
        <div>
          <div class="flex gap-4">
            <div class="w-16"></div>
            <div :for={shade <- ["0", "1", "2", "3", "4"]}>
              <div class="flex h-8 w-16 items-center justify-center text-sm font-medium text-gray-600">
                {shade}
              </div>
            </div>
          </div>
          <div class="flex gap-4">
            <div class="flex h-16 w-16 items-center justify-center text-sm font-medium text-gray-600">
              surface
            </div>
            <div :for={shade <- ["0", "1", "2", "3", "4"]} class="text-sm font-medium text-gray-600">
              <div class="h-16 w-16 rounded">
                <div class={"bg-surface-#{shade} h-full w-full rounded"}></div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Alpha Colors -->
        <div class="mt-4">
          <div class="flex gap-4">
            <div class="w-16"></div>
            <div
              :for={shade <- ["4", "8", "16", "24", "32", "40", "64", "72", "80", "88"]}
              class="text-sm font-medium text-gray-600"
            >
              <div class="flex h-8 w-16 items-center justify-center text-sm font-medium text-gray-600">
                {shade}
              </div>
            </div>
          </div>
          <div class="flex gap-4">
            <div class="flex h-16 w-16 items-center justify-center text-sm font-medium text-gray-600">
              alpha
            </div>
            <div :for={shade <- ["4", "8", "16", "24", "32", "40", "64", "72", "80", "88"]}>
              <div class="h-16 w-16 rounded">
                <div class={"bg-alpha-#{shade} h-full w-full rounded"}></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
