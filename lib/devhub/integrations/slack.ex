defmodule Devhub.Integrations.Slack do
  @moduledoc false
  use Tesla

  alias Devhub.Integrations

  require Logger

  plug Tesla.Middleware.OpenTelemetry
  plug Tesla.Middleware.JSON, encode_content_type: "application/json; charset=utf-8"

  @spec post_message(String.t(), String.t(), String.t() | nil, message :: map()) :: {:ok, map()} | {:error, any()}
  def post_message(organization_id, channel, reply_to \\ nil, message) do
    with {:ok, integration} <- Integrations.get_by(organization_id: organization_id, provider: :slack),
         {:ok, %{"bot_token" => token}} <- Jason.decode(integration.access_token),
         {:ok, %{body: %{"ts" => timestamp, "channel" => channel}}} <-
           post(
             "https://slack.com/api/chat.postMessage",
             %{
               channel: channel,
               thread_ts: reply_to,
               blocks: Map.get(message, :blocks, []),
               attachments: Map.get(message, :attachments, [])
             },
             headers: [{"Authorization", "Bearer #{token}"}]
           ) do
      {:ok, %{channel: channel, timestamp: timestamp}}
    else
      error ->
        Logger.error("Failed to post message: #{inspect(error)}")
        {:error, :failed_to_post_message}
    end
  end

  def query_request(
        %{query: query_string, credential: %{database: %{slack_channel: channel}}, user: %{name: name}} = query
      )
      when is_binary(channel) do
    with {:ok, %{body: %{"ts" => timestamp, "channel" => channel}}} <-
           post_message(query.organization_id, channel, %{
             blocks: [%{type: "section", text: %{type: "mrkdwn", text: "#{name} submitted a query for review"}}],
             attachments: [
               %{
                 blocks: [
                   %{type: "section", text: %{type: "mrkdwn", text: "```#{query_string}```"}},
                   %{
                     type: "section",
                     text: %{
                       type: "mrkdwn",
                       text: "<#{DevhubWeb.Endpoint.url()}/querydesk/pending-queries?query_id=#{query.id}|Review Query>"
                     }
                   }
                 ]
               }
             ]
           }) do
      {:ok, %{channel: channel, timestamp: timestamp}}
    end
  end

  def query_request(_query), do: {:error, :no_slack_channel}

  def query_approved(%{slack_message_ts: slack_message_ts} = query) when is_binary(slack_message_ts) do
    with {:ok, integration} <- Integrations.get_by(organization_id: query.organization_id, provider: :slack),
         {:ok, %{"bot_token" => token}} <- Jason.decode(integration.access_token) do
      post(
        "https://slack.com/api/reactions.add",
        %{timestamp: slack_message_ts, channel: query.slack_channel, name: "white_check_mark"},
        headers: [{"Authorization", "Bearer #{token}"}]
      )
    end
  end

  def query_approved(_query), do: {:error, :no_slack_message_ts}
end
