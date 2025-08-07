defmodule Devhub.TerraDesk.Utils.StreamLog do
  @moduledoc false
  alias Devhub.Integrations.Kubernetes.Client

  @spec stream_log(String.t(), String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, :failed_to_get_log}
  def stream_log(topic_id, pod, container, log_acc \\ "") do
    case Client.get_log(pod, container) do
      {:ok, %{body: body}} ->
        log =
          body
          |> Stream.each(fn data ->
            Phoenix.PubSub.broadcast(Devhub.PubSub, topic_id, {:shell_output, data})
            Phoenix.PubSub.broadcast(Devhub.PubSub, "agent", {:pubsub, topic_id, {:shell_output, data}})
          end)
          |> Enum.join("")

        {:ok, log_acc <> "\n" <> log}

      {:error, :failed_to_get_log} ->
        {:error, :failed_to_get_log, log_acc}
    end
  end
end
