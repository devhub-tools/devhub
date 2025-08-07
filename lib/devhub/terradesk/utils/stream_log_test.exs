defmodule Devhub.TerraDesk.Utils.StreamLogTest do
  use Devhub.DataCase, async: true

  import Devhub.TerraDesk.Utils.StreamLog

  alias Devhub.Integrations.Kubernetes
  alias Phoenix.PubSub

  test "can stream log" do
    topic_id = Ecto.UUID.generate()

    expect(Kubernetes.Client, :get_log, fn "pod-name", "container" ->
      TeslaHelper.response(body: ["log\n", "log\n", "log\n"])
    end)

    PubSub.subscribe(Devhub.PubSub, topic_id)

    assert {:ok, "\nlog\nlog\nlog\n"} = stream_log(topic_id, "pod-name", "container")

    assert_received {:shell_output, "log\n"}
    assert_received {:shell_output, "log\n"}
    assert_received {:shell_output, "log\n"}
  end
end
