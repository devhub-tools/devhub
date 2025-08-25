defmodule Devhub.Workflows.Actions.Continue do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Slack
  alias Devhub.Jwt
  alias Devhub.QueryDesk
  alias Devhub.Repo
  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Run
  alias Devhub.Workflows.Schemas.Step
  alias Devhub.Workflows.Schemas.Step.QueryAction

  require Logger

  @callback continue(Run.t()) :: {:ok, Run.t()}
  def continue(%Run{status: :in_progress} = run) do
    with %Run.Step{} = step <- next_step(run),
         {:ok, %Run{status: :in_progress} = run} <- run_step(run, step) do
      continue(run)
    else
      {:ok, %Run{status: :waiting_for_approval} = run} ->
        {:ok, run}

      {:ok, %Run{status: :failed} = run} ->
        {:ok, run}

      :all_steps_completed ->
        all_steps_completed(run)
    end
  end

  def continue(run), do: {:ok, run}

  defp next_step(run) do
    Enum.find(run.steps, :all_steps_completed, &(&1.status == :pending))
  end

  defp run_step(run, %Run.Step{condition: condition} = step) when is_binary(condition) do
    condition = Workflows.replace_variables(run.input, condition, run.steps)

    case Abacus.eval(condition) do
      {:ok, value} ->
        if (value && true) || false do
          do_run_step(run, %{step | condition: condition})
        else
          mark_step_completed({:ok, status: :skipped, condition: condition}, run, step)
        end

      _error ->
        mark_step_completed({:error, condition: condition}, run, step)
    end
  end

  defp run_step(run, step) do
    do_run_step(run, step)
  end

  defp do_run_step(run, %Run.Step{action: %Step.ApiAction{} = action} = step) do
    headers = Enum.map(action.headers, fn header -> {header.key, header.value} end)

    headers =
      if action.include_devhub_jwt do
        private_key = Application.get_env(:devhub, :signing_key)
        signer = Joken.Signer.create("ES256", %{"pem" => private_key})

        {:ok, token, _claims} =
          Jwt.generate_and_sign(
            %{
              "aud" => action.endpoint,
              "sub" => run.id,
              "workflow_id" => run.workflow_id
            },
            signer
          )

        [{"x-devhub-jwt", token} | headers]
      else
        headers
      end

    body = action.body && Workflows.replace_variables(run.input, action.body, run.steps)

    [url: action.endpoint, method: action.method, body: body, headers: headers]
    |> Tesla.request()
    |> case do
      {:ok, %{status: status_code, body: body}} when status_code == action.expected_status_code ->
        body =
          case Jason.decode(body) do
            {:ok, output} -> output
            _not_json -> body
          end

        {:ok, output: %{"status_code" => status_code, "body" => body}}

      {:ok, %{status: status_code, body: body}} ->
        body =
          case Jason.decode(body) do
            {:ok, output} -> output
            _not_json -> body
          end

        {:error, output: %{"status_code" => status_code, "body" => body}}

      {:error, error} ->
        {:error, output: %{"error" => error}}
    end
    |> mark_step_completed(run, step)
  end

  defp do_run_step(run, %Run.Step{action: %Step.ConditionAction{} = action} = step) do
    condition = Workflows.replace_variables(run.input, action.condition, run.steps)

    case Abacus.eval(condition) do
      {:ok, value} ->
        eval = (value && true) || false

        # we only want to set the run status if the condition isn't truthy
        mark_step_completed(
          {:ok, output: %{"eval" => eval}, action: %{action | condition: condition}},
          run,
          step,
          run_status: if(!eval, do: action.when_false)
        )

      _error ->
        mark_step_completed({:error, output: %{"eval" => "error"}, action: %{action | condition: condition}}, run, step)
    end
  end

  defp do_run_step(run, %Run.Step{action: %QueryAction{} = action} = step) do
    query_string = Workflows.replace_variables(run.input, action.query, run.steps)

    result =
      with {:ok, query} <-
             QueryDesk.create_query(%{
               organization_id: run.organization_id,
               credential_id: action.credential_id,
               query: query_string,
               is_system: true,
               timeout: action.timeout
             }),
           {:ok, result, query} <- QueryDesk.run_query(query) do
        result = QueryAction.format_result(result)

        {:ok, output: result, query_id: query.id}
      else
        {:error, error, query} -> {:error, output: %{"error" => error}, query_id: query.id}
        {:error, error} -> {:error, output: %{"error" => error}}
      end

    mark_step_completed(result, run, step)
  end

  defp do_run_step(run, %Run.Step{action: %Step.SlackAction{} = action} = step) do
    message = action.message && Workflows.replace_variables(run.input, action.message, run.steps)

    run.organization_id
    |> Slack.post_message(action.slack_channel, %{
      blocks: [
        %{type: "section", text: %{type: "mrkdwn", text: message}},
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: "<#{DevhubWeb.Endpoint.url()}/workflows/#{run.workflow_id}/runs/#{run.id}|#{action.link_text}>"
          }
        }
      ]
    })
    |> case do
      {:ok, %{channel: channel, timestamp: timestamp}} ->
        {:ok,
         output: %{"channel" => channel, "timestamp" => timestamp}, message: message, action: %{action | message: message}}

      {:error, error} ->
        {:error, output: %{"error" => error}, action: %{action | message: message}}
    end
    |> mark_step_completed(run, step)
  end

  defp do_run_step(run, %Run.Step{action: %Step.SlackReplyAction{} = action} = step) do
    message = action.message && Workflows.replace_variables(run.input, action.message, run.steps)
    reply_to_step = Enum.find(run.steps, fn step -> step.name == action.reply_to_step_name end)

    run.organization_id
    |> Slack.post_message(reply_to_step.output["channel"], reply_to_step.output["timestamp"], %{
      blocks: [%{type: "section", text: %{type: "mrkdwn", text: message}}]
    })
    |> case do
      {:ok, %{channel: channel, timestamp: timestamp}} ->
        {:ok,
         output: %{"channel" => channel, "timestamp" => timestamp}, message: message, action: %{action | message: message}}

      {:error, error} ->
        {:error, output: %{"error" => error}, action: %{action | message: message}}
    end
    |> mark_step_completed(run, step)
  end

  defp do_run_step(run, %Run.Step{action: %Step.ApprovalAction{}}) do
    run
    |> Run.changeset(%{status: :waiting_for_approval})
    |> Repo.update()
  end

  defp all_steps_completed(run) do
    steps = run.steps

    status =
      ((Enum.all?(steps, &(&1.status in [:succeeded, :skipped])) and not Enum.empty?(steps)) && :completed) || :failed

    run
    |> Run.changeset(%{status: status})
    |> Repo.update()
  end

  defp mark_step_completed(output, run, %Run.Step{} = finished_step, opts \\ []) do
    updates =
      case output do
        {:ok, updates} when is_list(updates) -> updates |> Keyword.put_new(:status, :succeeded) |> Map.new()
        {:error, updates} when is_list(updates) -> updates |> Keyword.put(:status, :failed) |> Map.new()
      end

    steps =
      Enum.map(
        run.steps,
        fn step ->
          step =
            if(finished_step.workflow_step_id == step.workflow_step_id,
              do: Map.merge(finished_step, updates),
              else: step
            )

          type = PolymorphicEmbed.get_polymorphic_type(step.__struct__, :action, step.action)
          action = step.action |> Map.from_struct() |> Map.put(:__type__, type)

          step
          |> Map.from_struct()
          |> Map.put(:action, action)
        end
      )

    status = if updates.status == :failed, do: :failed, else: opts[:run_status] || :in_progress

    run
    |> Run.changeset(%{steps: steps, status: status})
    |> Repo.update()
  end
end
