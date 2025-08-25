defmodule DevhubWeb.Helpers do
  @moduledoc """
  Component helpers
  """

  alias Devhub.Users

  def ok(socket) do
    {:ok, socket}
  end

  def noreply(socket) do
    {:noreply, socket}
  end

  def cont(socket) do
    {:cont, socket}
  end

  def halt(socket) do
    {:halt, socket}
  end

  def start_date_from_params(params) do
    case Date.from_iso8601(params["start_date"] || "") do
      {:ok, date} -> date
      _error -> Date.utc_today() |> Date.add(-84) |> Timex.beginning_of_week()
    end
  end

  def end_date_from_params(timezone, params) do
    case Date.from_iso8601(params["end_date"] || "") do
      {:ok, date} -> date
      _error -> timezone |> Timex.now() |> Timex.to_date()
    end
  end

  def save_preferences_and_patch(socket, preferences_key, key, params) do
    user = socket.assigns.user
    filters = user.preferences[preferences_key] || %{}

    new_filters =
      (filters[key] || %{})
      |> Map.merge(params)
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Map.new()

    preferences = Map.put(user.preferences || %{}, preferences_key, Map.put(filters, key, new_filters))
    {:ok, user} = Users.update_user(user, %{preferences: preferences})

    params =
      (socket.assigns.uri.query || "")
      |> URI.decode_query()
      |> Map.merge(params)
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Map.new()

    query = URI.encode_query(params)

    socket
    |> Phoenix.Component.assign(user: user)
    |> Phoenix.LiveView.push_patch(to: "#{socket.assigns.uri.path}?#{query}")
  end

  @spec unique_id() :: String.t()
  def unique_id do
    16 |> :crypto.strong_rand_bytes() |> Base.encode16()
  end

  def focus_class, do: "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500"

  def pluralize_unit(1, unit), do: "1 #{unit}"
  def pluralize_unit(units, unit), do: "#{units} #{unit}s"

  def maybe_base64_decode(content) when is_binary(content) do
    Base.decode64!(content, ignore: :whitespace)
  end

  def maybe_base64_decode(_content), do: nil

  @doc """
  Calculate limit of checks to display.

  This leaves width of color bar ~8-9px accounting for page padding and margins between bars.

  Our goal is to display as many bars as possible.
  There are visual distortions when the bars are too small.
  """
  def calculate_checks_limit(width) do
    # - page padding (x2)
    (width / 8 - 24 * 2)
    |> Decimal.from_float()
    |> Decimal.round(0)
    |> Decimal.to_integer()
    |> max(30)
  end

  def hex_to_rgba("#" <> hex, alpha \\ 1) do
    {r, hex} = String.split_at(hex, 2)
    {g, hex} = String.split_at(hex, 2)
    {b, ""} = String.split_at(hex, 2)
    "rgba(#{String.to_integer(r, 16)}, #{String.to_integer(g, 16)}, #{String.to_integer(b, 16)}, #{alpha})"
  end

  def start_passkey_authentication(socket, user, event) do
    passkeys = Users.get_passkeys(user)
    allow_credentials = Enum.map(passkeys, &{&1.raw_id, :erlang.binary_to_term(&1.public_key)})
    challenge = Wax.new_authentication_challenge(allow_credentials: allow_credentials)

    socket
    |> Phoenix.Component.assign(challenge: challenge, allow_credentials: allow_credentials)
    |> Phoenix.LiveView.push_event("start_passkey_authentication", %{
      phxEvent: event,
      challenge: Base.encode64(challenge.bytes),
      credIds: Enum.map(passkeys, & &1.raw_id)
    })
  end

  def register_passkey(conn, params, user) do
    challenge = Plug.Conn.get_session(conn, :registration_challenge)

    with {:ok, attestation_object} <- Base.decode64(params["attestationObject"]),
         {:ok, {authenticator_data, _result}} <- Wax.register(attestation_object, params["clientDataJSON"], challenge) do
      aaguid = Wax.AuthenticatorData.get_aaguid(authenticator_data)

      Users.register_passkey(user, %{
        raw_id: params["rawId"],
        public_key: :erlang.term_to_binary(authenticator_data.attested_credential_data.credential_public_key),
        aaguid: aaguid
      })
    end
  end

  def patch_current(socket, params) do
    params = socket |> update_uri_query(params) |> URI.encode_query()
    Phoenix.LiveView.push_patch(socket, to: "#{socket.assigns.uri.path}?#{params}")
  end

  def update_uri_query(socket, params) do
    (socket.assigns.uri.query || "")
    |> URI.decode_query()
    |> Map.merge(params)
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
    |> Map.new()
  end
end
