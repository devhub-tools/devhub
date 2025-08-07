defmodule Devhub.TerraDesk.Actions.PlanChanges do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.TerraDesk.Schemas.Plan
  alias Devhub.TerraDesk.Utils.AnsiToHTML

  @callback plan_changes(Plan.t()) :: [String.t()]
  def plan_changes(plan) do
    if String.contains?(plan.log || "", "will perform the following actions:") do
      plan.log
      # get everything after the "Terraform/OpenTofu will perform the following actions:" section
      |> String.split("will perform the following actions:")
      |> List.last()
      # get everything before the "Plan:" section
      |> String.split("Plan:")
      |> List.first()
      # each resource is separated by two newlines
      |> String.split("\n\n\e[1m  #", trim: true)
      # get the first line separately as the resource name
      |> Enum.map(fn resource ->
        [summary, details] = resource |> String.split("\n", parts: 2) |> Enum.map(&AnsiToHTML.generate_html/1)

        name =
          case Regex.run(~r/^ (.*?)\e/, resource) do
            [_full, resource_name] -> String.trim(resource_name)
            _no_match -> nil
          end

        %{name: name, summary: summary, details: details}
      end)
    else
      []
    end
  end
end
