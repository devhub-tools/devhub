defmodule Devhub.Utils.Base58 do
  @moduledoc """
  `Base58` provides two functions: `encode/1` and `decode/1`.
  `encode/1` takes an **Elixir binary** (_String, Number, etc._)
  and returns a Base58 encoded String.
  `decode/1` receives a Base58 encoded String and returns a binary.
  """

  @alnum ~c(123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz)

  @doc """
  ## Examples

    iex>  Devhub.Utils.Base58.encode("hello")
    "Cn8eVZg"

    iex>  Devhub.Utils.Base58.encode(42)
    "4yP"
  """
  def encode(e) when is_integer(e) or is_float(e) or is_atom(e), do: encode("#{e}")
  # see https://github.com/dwyl/base58/issues/5#issuecomment-459088540
  def encode(<<0, binary::binary>>), do: "1" <> encode(binary)
  def encode(""), do: ""
  # see https://github.com/dwyl/base58/pull/3#discussion_r252291127
  def encode(binary), do: encode(:binary.decode_unsigned(binary), "")
  def encode(0, acc), do: acc
  def encode(n, acc), do: encode(div(n, 58), <<Enum.at(@alnum, rem(n, 58))>> <> acc)

  @doc """
  `decode/1` decodes the given Base58 string back to binary.
  ## Examples

    iex>  Devhub.Utils.Base58.encode("hello") |>  Devhub.Utils.Base58.decode()
    {:ok, "hello"}
  """

  def decode(content) do
    {:ok, do_decode(content)}
  rescue
    _error -> :error
  end

  # return empty string unmodified
  defp do_decode(""), do: ""
  # treat null values as empty
  defp do_decode("\0"), do: ""

  defp do_decode(binary) do
    {zeroes, binary} = handle_leading_zeroes(binary)
    zeroes <> do_decode(binary, 0)
  end

  defp do_decode("", 0), do: ""
  defp do_decode("", acc), do: :binary.encode_unsigned(acc)
  defp do_decode(<<head, tail::binary>>, acc), do: do_decode(tail, acc * 58 + Enum.find_index(@alnum, &(&1 == head)))

  defp handle_leading_zeroes(binary) do
    # avoid dropping leading zeros -- see https://github.com/dwyl/base58/issues/27
    origlen = String.length(binary)
    binary = String.trim_leading(binary, <<List.first(@alnum)>>)
    newlen = String.length(binary)
    {String.duplicate(<<0>>, origlen - newlen), binary}
  end
end
