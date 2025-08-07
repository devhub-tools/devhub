defmodule Devhub.Agents.Actions.OnlineTest do
  # needs to be async: false for db calls in web request
  use Devhub.DataCase, async: false

  alias Devhub.Agents

  test "success" do
    %{id: organization_id} = insert(:organization)
    agent = insert(:agent, organization_id: organization_id)

    refute Agents.online?(agent.id)

    token = Phoenix.Token.sign(DevhubWeb.Endpoint, "agent token", agent.id)
    Application.put_env(:devhub, :agent_config, %{"token" => token})

    Phoenix.PubSub.subscribe(Devhub.PubSub, agent.id)

    {:ok, _pid} = Devhub.Agents.Client.start_link(name: __MODULE__)

    assert_receive :connected

    assert Agents.online?(agent)
  end
end
