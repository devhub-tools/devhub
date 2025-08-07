defmodule Devhub.Workflows.Actions.ReplaceVariablesTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Run
  alias Devhub.Workflows.Schemas.Step

  test "replaces variables" do
    steps = [
      %Run.Step{
        name: "email-lookup",
        action: %Step.ApiAction{endpoint: "https://slack.com/api/users.lookupByEmail"},
        output: %{"body" => %{"user" => %{"name" => "michael"}}}
      },
      %Run.Step{
        name: "get-user",
        action: %Step.QueryAction{query: "SELECT id FROM users"},
        output: %{
          "rows" => [["usr_01JRK0PQ95BDPB29Q8011REGVY"]],
          "columns" => [
            "id"
          ],
          "command" => "select",
          "messages" => [],
          "num_rows" => 2,
          "connection_id" => 20_815
        }
      }
    ]

    assert "Hi @michael, michael@devhub.tools has requested an mfa reset" =
             Workflows.replace_variables(
               %{email: "michael@devhub.tools"},
               "Hi @${step.email-lookup.output.body.user.name}, ${email} has requested an mfa reset",
               steps
             )

    assert "Here is the user id: @usr_01JRK0PQ95BDPB29Q8011REGVY" =
             Workflows.replace_variables(
               %{email: "michael@devhub.tools"},
               "Here is the user id: @${step.get-user.output.rows[0][0]}",
               steps
             )

    timestamp = DateTime.to_unix(DateTime.utc_now())
    "timestamp: " <> replaced_timestamp = Workflows.replace_variables(%{}, "timestamp: ${timestamp}", [])
    assert timestamp <= String.to_integer(replaced_timestamp)
  end

  test "handles invalid step" do
    steps = [
      %Run.Step{
        name: "lookup",
        action: %Step.ApiAction{endpoint: "https://slack.com/api/users.lookupByEmail"},
        output: %{"body" => %{"user" => %{"name" => "michael"}}}
      }
    ]

    assert "Hi @${step.email-lookup.output.body.user.name} (step lookup failed), michael@devhub.tools has requested an mfa reset" =
             Workflows.replace_variables(
               %{email: "michael@devhub.tools"},
               "Hi @${step.email-lookup.output.body.user.name}, ${email} has requested an mfa reset",
               steps
             )
  end
end
