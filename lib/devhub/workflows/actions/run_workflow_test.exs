defmodule Devhub.Workflows.Actions.RunWorkflowTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows
  alias Devhub.Workflows.Jobs.RunWorkflow
  alias Devhub.Workflows.Schemas.Run

  test "parses inputs correctly" do
    workflow =
      insert(:workflow,
        inputs: [
          %{key: "string", type: :string},
          %{key: "integer", type: :integer},
          %{key: "float", type: :float},
          %{key: "boolean", type: :boolean}
        ]
      )

    assert {:ok,
            %Run{
              id: run_id,
              input: %{
                "boolean" => true,
                "float" => 1.0,
                "integer" => 1,
                "string" => "hello world"
              }
            }} =
             Workflows.run_workflow(workflow, %{
               "string" => "hello world",
               "integer" => "1",
               "float" => "1.0",
               "boolean" => "true"
             })

    assert_enqueued worker: RunWorkflow, args: %{"id" => run_id}

    # should trim whitespace
    assert {:ok,
            %Run{
              input: %{
                "boolean" => true,
                "float" => 1.0,
                "integer" => 1,
                "string" => "hello world"
              }
            }} =
             Workflows.run_workflow(workflow, %{
               "string" => " hello world ",
               "integer" => " 1 ",
               "float" => " 1.0 ",
               "boolean" => " true "
             })
  end

  test "handles invalid inputs" do
    workflow =
      insert(:workflow,
        inputs: [%{key: "string", type: :string}, %{key: "integer", type: :integer}, %{key: "float", type: :float}]
      )

    assert {:error, :invalid_input} = Workflows.run_workflow(workflow, %{"string" => nil})

    assert {:error, :invalid_input} =
             Workflows.run_workflow(workflow, %{"string" => "", "integer" => "1.0", "float" => "1.0"})

    assert {:error, :invalid_input} =
             Workflows.run_workflow(workflow, %{"string" => "", "integer" => "1", "float" => "bad"})

    refute_enqueued worker: RunWorkflow
  end

  test "handles failure" do
    workflow = insert(:workflow)
    expect(Devhub.Repo, :insert, fn changeset -> {:error, changeset} end)
    assert {:error, :failed_to_run_workflow} = Workflows.run_workflow(workflow, %{})
  end
end
