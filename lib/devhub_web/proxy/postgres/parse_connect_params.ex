defmodule DevhubWeb.Proxy.Postgres.ParseConnectParams do
  @moduledoc false

  alias DevhubWeb.Proxy.Postgres.ClientState

  def parse_connect_params(%ClientState{} = state, <<_protocol::unsigned-integer-32, connect_params::binary>>) do
    connect_params =
      connect_params
      |> String.trim_trailing(<<0>>)
      |> String.split(<<0>>)
      |> do_parse_connect_params()

    %{state | connect_params: connect_params}
  end

  defp do_parse_connect_params(["", <<3>>, "" | rest]) do
    do_parse_connect_params(rest, %{})
  end

  defp do_parse_connect_params([], params) do
    params
  end

  defp do_parse_connect_params([key, value | rest], params) do
    do_parse_connect_params(rest, Map.put(params, key, value))
  end
end
