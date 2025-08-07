defmodule DevhubWeb.Components.Workflows.Status do
  @moduledoc false
  use DevhubWeb, :html

  def status(assigns) do
    color =
      case assigns.status do
        :approved -> "bg-green-200 text-green-800"
        :succeeded -> "bg-green-200 text-green-800"
        :completed -> "bg-green-200 text-green-800"
        :in_progress -> "bg-yellow-400 text-yellow-900"
        :pending -> "bg-yellow-400 text-yellow-900"
        :waiting_for_approval -> "bg-yellow-400 text-yellow-900"
        :failed -> "bg-red-200 text-red-800"
        :canceled -> "bg-gray-200 text-gray-800"
        :skipped -> "bg-gray-200 text-gray-800"
      end

    title = assigns.status |> to_string() |> String.replace("_", " ") |> String.capitalize()

    assigns = assign(assigns, title: title, color: color)

    ~H"""
    <span class={"#{@color} inline-flex items-center rounded px-2 py-1 text-xs"}>
      {@title}
    </span>
    """
  end
end
