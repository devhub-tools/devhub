defmodule DevhubWeb.Components.QuerySummary do
  @moduledoc false
  use DevhubWeb, :html

  slot :inner_block

  def query_summary(assigns) do
    ~H"""
    <div class="grid w-full grid-cols-7 items-center justify-start gap-x-4">
      <div class="col-span-2">
        <div class="flex flex-col gap-y-1">
          <div class="mb-2 truncate text-left">{@query.query}</div>

          <p class="truncate text-left text-xs text-gray-600">
            <span class="text-alpha-64">database:</span> {@query.credential.database.name}
          </p>
          <p class="truncate text-left text-xs text-gray-600">
            <span class="text-alpha-64">user:</span> {@query.credential.username}
          </p>
          <p class="truncate text-left text-xs text-gray-600">
            <span class="text-alpha-64">timeout:</span> {@query.timeout}s
          </p>
          <p class="truncate text-left text-xs text-gray-600">
            <span class="text-alpha-64">auto run:</span> {@query.run_on_approval}
          </p>
          <p class="truncate text-left text-xs text-gray-600">
            <span class="text-alpha-64">last edited:</span>
            <format-date date={@query.updated_at} format="relative-datetime" />
          </p>
        </div>
      </div>
      <div class="col-span-2 pl-2">
        <.user_block user={@query.user} />
      </div>
      <div class="flex flex-col items-end space-y-1">
        <%= if @query.credential.reviews_required > 0 or length(@query.approvals) > 0 do %>
          <p class="text-sm">
            {length(@query.approvals)} / {@query.credential.reviews_required}
          </p>
          <p class="text-xs">
            approvals
          </p>
        <% end %>
      </div>
      <div class="col-span-2">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
