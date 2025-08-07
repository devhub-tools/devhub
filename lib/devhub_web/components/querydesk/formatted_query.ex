defmodule DevhubWeb.Components.Querydesk.FormattedQuery do
  @moduledoc false
  use DevhubWeb, :html

  attr :background_color, :string, default: "bg-surface-2"
  attr :class, :string, default: nil

  def formatted_query(assigns) do
    queries = String.split(assigns.query, ";", trim: true)

    assigns = assign(assigns, queries: queries)

    ~H"""
    <div
      :for={{query, index} <- Enum.with_index(@queries)}
      class={["mt-4 overflow-auto rounded p-4 text-sm", @background_color, @class]}
    >
      <pre id={"#{@id}-#{index}"} phx-hook="SqlHighlight" data-query={query} data-adapter={@adapter} />
    </div>
    """
  end
end
