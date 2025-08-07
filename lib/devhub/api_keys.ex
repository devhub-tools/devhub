defmodule Devhub.ApiKeys do
  @moduledoc """
  The Api Keys context.

  We require the tokens to be prefixed with the account id for rate limiting purposes
  which is enforced by cloudflare. We need to make sure to validate the api key belongs
  to the prefixed account id.
  """
  @behaviour Devhub.ApiKeys.Actions.Create
  @behaviour Devhub.ApiKeys.Actions.List
  @behaviour Devhub.ApiKeys.Actions.Revoke
  @behaviour Devhub.ApiKeys.Actions.Update
  @behaviour Devhub.ApiKeys.Actions.Verify

  alias Devhub.ApiKeys.Actions

  @impl Actions.Verify
  defdelegate verify(token), to: Actions.Verify

  @impl Actions.Create
  defdelegate create(organization, name, permissions), to: Actions.Create

  @impl Actions.Update
  defdelegate update(api_key, name, permissions), to: Actions.Update

  @impl Actions.List
  defdelegate list(organization), to: Actions.List

  @impl Actions.Revoke
  defdelegate revoke(api_key_id), to: Actions.Revoke
end
