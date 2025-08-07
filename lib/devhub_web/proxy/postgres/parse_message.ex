defmodule DevhubWeb.Proxy.Postgres.ParseMessage do
  @moduledoc false

  def parse_message(<<8::integer-32, 1234::integer-16, 5679::integer-16>> = bin) do
    case bin do
      <<msg_body::binary-size(8), final_rest::binary>> ->
        {:ok, {{:msgSSLRequest, nil}, msg_body}, final_rest}

      _other ->
        {:continuation,
         fn data ->
           handle_continuation(8, {:msgSSLRequest, nil}, bin, data)
         end}
    end
  end

  def parse_message(<<len::unsigned-integer-32, protocol::unsigned-integer-32, _rest::binary>> = bin)
      when protocol == 196_608 do
    case bin do
      <<msg_body::binary-size(len), final_rest::binary>> ->
        {:ok, {{:msgStartup, nil}, msg_body}, final_rest}

      _other ->
        {:continuation,
         fn data ->
           handle_continuation(len, {:msgStartup, nil}, bin, data)
         end}
    end
  end

  def parse_message(<<c::size(8)>>) do
    tag = tag_to_msg_type(c)
    {:ok, {{tag, c}, ""}, ""}
  end

  def parse_message(<<c::size(8), rest::binary>>) do
    tag = tag_to_msg_type(c)

    <<len::unsigned-integer-32, _other_rest::binary>> = rest

    case rest do
      <<msg_body::binary-size(len), final_rest::binary>> ->
        {:ok, {{tag, c}, msg_body}, final_rest}

      _other ->
        {:continuation,
         fn data ->
           handle_continuation(len, {tag, c}, rest, data)
         end}
    end
  end

  defp handle_continuation(l, tag, other, data) do
    new_data = other <> data

    case new_data do
      <<msg_body::binary-size(l), rest::binary>> ->
        {:ok, {tag, msg_body}, rest}

      _other ->
        {:continuation,
         fn data ->
           handle_continuation(l, tag, new_data, data)
         end}
    end
  end

  # coveralls-ignore-start
  defp tag_to_msg_type(?1), do: :msgParseComplete
  defp tag_to_msg_type(?2), do: :msgBindComplete
  defp tag_to_msg_type(?3), do: :msgCloseComplete
  defp tag_to_msg_type(?A), do: :msgNotificationResponse
  defp tag_to_msg_type(?c), do: :msgCopyDone
  defp tag_to_msg_type(?C), do: :msgCommandComplete
  defp tag_to_msg_type(?d), do: :msgCopyData
  defp tag_to_msg_type(?D), do: :msgDataRow
  defp tag_to_msg_type(?E), do: :msgErrorResponse
  defp tag_to_msg_type(?f), do: :msgFail
  defp tag_to_msg_type(?G), do: :msgCopyInResponse
  defp tag_to_msg_type(?H), do: :msgCopyOutResponse
  defp tag_to_msg_type(?I), do: :msgEmptyQueryResponse
  defp tag_to_msg_type(?K), do: :msgBackendKeyData
  defp tag_to_msg_type(?n), do: :msgNoData
  defp tag_to_msg_type(?N), do: :msgNoticeResponse
  defp tag_to_msg_type(?R), do: :msgAuthentication
  defp tag_to_msg_type(?s), do: :msgPortalSuspended
  defp tag_to_msg_type(?S), do: :msgSync
  defp tag_to_msg_type(?t), do: :msgParameterDescription
  defp tag_to_msg_type(?T), do: :msgRowDescription
  defp tag_to_msg_type(?p), do: :msgPasswordMessage
  defp tag_to_msg_type(?W), do: :CopyBothResponse
  defp tag_to_msg_type(?Q), do: :msgQuery
  defp tag_to_msg_type(?X), do: :msgTerminate
  defp tag_to_msg_type(?Z), do: :msgReadyForQuery
  defp tag_to_msg_type(?P), do: :msgParse
  defp tag_to_msg_type(?B), do: :msgBind
  defp tag_to_msg_type(_byte), do: :msgNoTag
  # coveralls-ignore-stop
end
