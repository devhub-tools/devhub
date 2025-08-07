defmodule Devhub.Utils.RunShellCommand do
  @moduledoc false

  @spec run_shell_command(
          command :: String.t(),
          args :: list(String.t()),
          env :: [{charlist(), charlist()}],
          dir :: String.t(),
          topic_id :: String.t()
        ) ::
          {integer(), String.t()}
  def run_shell_command(command, args, env, dir, topic_id) do
    exec = System.find_executable(command)

    port =
      Port.open({:spawn_executable, exec}, [
        :stderr_to_stdout,
        :binary,
        :exit_status,
        cd: dir,
        env: env,
        args: args
      ])

    stream_output(port, topic_id)
  end

  defp stream_output(port, topic_id, acc \\ "") do
    receive do
      {^port, {:data, data}} ->
        Phoenix.PubSub.broadcast(Devhub.PubSub, topic_id, {:shell_output, data})
        Phoenix.PubSub.broadcast(Devhub.PubSub, "agent", {:pubsub, topic_id, {:shell_output, data}})
        stream_output(port, topic_id, acc <> data)

      {^port, {:exit_status, status}} ->
        {status, acc}
    end
  end
end
