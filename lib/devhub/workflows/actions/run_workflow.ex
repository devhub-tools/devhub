defmodule Devhub.Workflows.Actions.RunWorkflow do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Workflows.Jobs.RunWorkflow
  alias Devhub.Workflows.Schemas.Run
  alias Devhub.Workflows.Schemas.Workflow

  @callback run_workflow(Workflow.t(), map()) ::
              {:ok, Run.t()} | {:error, :invalid_input} | {:error, :failed_to_run_workflow}
  def run_workflow(workflow, params) do
    additional_params = %{
      triggered_by_linear_issue_id: params["triggered_by_linear_issue_id"],
      triggered_by_user_id: params["triggered_by_user_id"]
    }

    Repo.transaction(fn ->
      with {:ok, input} <- parse_input(workflow, params),
           {:ok, run} <- create_workflow_run(workflow, input, additional_params),
           {:ok, _job} <- %{id: run.id} |> RunWorkflow.new() |> Oban.insert() do
        run
      else
        {:error, :invalid_input} ->
          Repo.rollback(:invalid_input)

        _error ->
          Repo.rollback(:failed_to_run_workflow)
      end
    end)
  end

  defp parse_input(workflow, params) do
    Enum.reduce_while(workflow.inputs, {:ok, %{}}, fn input, {:ok, acc} ->
      case parse_type(params[input.key], input.type) do
        {:ok, value} -> {:cont, {:ok, Map.put(acc, input.key, value)}}
        {:error, :invalid_input} -> {:halt, {:error, :invalid_input}}
      end
    end)
  end

  defp create_workflow_run(workflow, input, additional_params) do
    steps =
      Enum.map(workflow.steps, fn step ->
        %{
          workflow_step_id: step.id,
          name: step.name,
          condition: step.condition,
          action:
            step.action
            |> Map.from_struct()
            |> Map.put(:__type__, PolymorphicEmbed.get_polymorphic_type(step.__struct__, :action, step.action))
        }
      end)

    %{
      status: :in_progress,
      input: input,
      organization_id: workflow.organization_id,
      workflow_id: workflow.id,
      steps: steps
    }
    |> Map.merge(additional_params)
    |> Run.changeset()
    |> Repo.insert()
  end

  defp parse_type(nil, _type), do: {:error, :invalid_input}
  defp parse_type(value, :string), do: {:ok, String.trim("#{value}")}

  defp parse_type(value, :integer) do
    {:ok, "#{value}" |> String.trim() |> String.to_integer()}
  rescue
    _error -> {:error, :invalid_input}
  end

  defp parse_type(value, :float) do
    {:ok, "#{value}" |> String.trim() |> String.to_float()}
  rescue
    _error -> {:error, :invalid_input}
  end

  defp parse_type(value, :boolean) when is_binary(value), do: {:ok, String.trim(value) == "true"}
  defp parse_type(value, :boolean) when is_boolean(value), do: {:ok, value}

  defp parse_type(_value, _type), do: {:error, :invalid_input}
end
