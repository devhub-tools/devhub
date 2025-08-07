defmodule Devhub.Uptime.Actions.PubSub do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Uptime.Schemas.Check

  @callback subscribe_checks() :: :ok | {:error, term()}
  @callback subscribe_checks(String.t()) :: :ok | {:error, term()}
  def subscribe_checks(service_id \\ "all") do
    Phoenix.PubSub.subscribe(Devhub.PubSub, "service:#{service_id}")
  end

  @callback unsubscribe_checks() :: :ok
  @callback unsubscribe_checks(String.t()) :: :ok
  def unsubscribe_checks(service_id \\ "all") do
    Phoenix.PubSub.unsubscribe(Devhub.PubSub, "service:#{service_id}")
  end

  @spec broadcast!(Check.t()) :: :ok
  def broadcast!(%Check{} = check) do
    Phoenix.PubSub.broadcast!(Devhub.PubSub, "service:all", {Check, check})
    Phoenix.PubSub.broadcast!(Devhub.PubSub, "service:#{check.service_id}", {Check, check})
  end
end
