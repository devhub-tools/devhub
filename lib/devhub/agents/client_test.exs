defmodule Devhub.Agents.ClientTest do
  # needs to be async: false for db calls in web request
  use Devhub.DataCase

  import ExUnit.CaptureLog

  alias Devhub.Agents.Client

  test "success" do
    %{id: organization_id} = insert(:organization)
    agent = insert(:agent, organization_id: organization_id)

    token = Phoenix.Token.sign(DevhubWeb.Endpoint, "agent token", agent.id)
    Application.put_env(:devhub, :agent_config, %{"token" => token})

    {:ok, _pid} = Client.start_link(name: __MODULE__)

    :timer.sleep(300)

    assert :ok = DevhubWeb.AgentConnection.send_command(agent.id, {__MODULE__, :do_task, []})

    # handles error
    assert capture_log(fn ->
             DevhubWeb.AgentConnection.send_command(agent.id, {__MODULE__, :do_error_task, []})
           end) =~ "Failed to run command: ** (RuntimeError) error"
  end

  def do_task do
    :ok
  end

  def do_error_task do
    raise "error"
  end
end
