defmodule Devhub.QueryDesk.Actions.CreateQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Slack
  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Repo

  @callback create_query(map()) :: {:ok, Query.t()} | {:error, Ecto.Changeset.t()}
  def create_query(params) do
    params
    |> Query.changeset()
    |> Repo.insert()
    |> maybe_post_to_slack()
  end

  defp maybe_post_to_slack({:ok, query}) do
    query = Repo.preload(query, [:user, credential: :database])

    # if reviews are required or they can't run the query, we post to slack
    with false <- query.credential.reviews_required == 0 or QueryDesk.can_run_query?(query),
         false <- query.analyze,
         {:ok, %{channel: channel, timestamp: timestamp}} <- Slack.query_request(query),
         {:ok, query} <- QueryDesk.update_query(query, %{slack_channel: channel, slack_message_ts: timestamp}) do
      {:ok, query}
    else
      _error -> {:ok, query}
    end
  end

  defp maybe_post_to_slack(result), do: result
end
