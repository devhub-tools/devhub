defmodule TeslaHelper do
  @moduledoc false
  @doc """
  Returns a reponse when mocking a Tesla client.

  ## Example

      Tesla
      |> expect(:call, fn _tesla_env, _opts ->
        Eggnog.TeslaHelper.response(status: 200, body: %{"status" => "approved"})
      end)
  """
  def response(args) do
    {:ok,
     %Tesla.Env{
       __client__: Keyword.get(args, :tesla_client, %Tesla.Client{}),
       status: Keyword.get(args, :status, 200),
       body: Keyword.get(args, :body),
       method: Keyword.get(args, :method, :get),
       url: Keyword.get(args, :url, ""),
       headers: Keyword.get(args, :headers, [])
     }}
  end
end
