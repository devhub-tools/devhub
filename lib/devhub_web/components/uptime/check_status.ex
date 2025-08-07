defmodule DevhubWeb.Components.Uptime.CheckStatus do
  @moduledoc false
  use DevhubWeb, :html

  def check_status(assigns) do
    class =
      case assigns.check.status do
        :success -> "bg-green-200 text-green-800"
        :pending -> "bg-yellow-400 text-yellow-900"
        :failure -> "bg-red-200 text-red-800"
        _unknown -> "bg-alpha-16 text-gray-800"
      end

    assigns = assign(assigns, class: class)

    ~H"""
    <div>
      <span class={["rounded p-1 py-0.5", @class]}>
        {@check.status}
      </span>
    </div>
    """
  end
end
