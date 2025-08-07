defmodule Devhub do
  @moduledoc """
  Devhub keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @behaviour Devhub.Actions.Search

  alias Devhub.Actions.Search

  def prod?, do: Application.get_env(:devhub, :compile_env) == :prod
  def dev?, do: Application.get_env(:devhub, :compile_env) == :dev
  def test?, do: Application.get_env(:devhub, :compile_env) == :test
  def cloud_hosted?, do: Application.get_env(:devhub, :cloud_hosted?)

  @impl Search
  defdelegate search(organization_user, search, opts \\ []), to: Search
end
