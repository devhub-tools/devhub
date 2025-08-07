defmodule Devhub.Integrations.SlackTest do
  use Devhub.DataCase, async: true

  test "query_request/1" do
    organization = insert(:organization)

    query =
      insert(:query,
        organization: organization,
        credential:
          build(:database_credential,
            database: build(:database, organization: organization, slack_channel: "#general")
          ),
        user: build(:user)
      )

    insert(:integration,
      organization: organization,
      provider: :slack,
      access_token: Jason.encode!(%{bot_token: "xoxb-1234567890"})
    )

    expect(Tesla.Adapter.Finch, :call, fn %Tesla.Env{
                                            method: :post,
                                            url: "https://slack.com/api/chat.postMessage",
                                            body: body
                                          },
                                          _opts ->
      assert {
               :ok,
               %{
                 "channel" => "#general",
                 "thread_ts" => nil,
                 "attachments" => [
                   %{
                     "blocks" => [
                       %{"text" => %{"text" => "```SELECT * FROM users```", "type" => "mrkdwn"}, "type" => "section"},
                       %{
                         "text" => %{
                           "text" =>
                             "<http://localhost:4002/querydesk/pending-queries?query_id=#{query.id}|Review Query>",
                           "type" => "mrkdwn"
                         },
                         "type" => "section"
                       }
                     ]
                   }
                 ],
                 "blocks" => [
                   %{
                     "text" => %{"text" => "John Doe submitted a query for review", "type" => "mrkdwn"},
                     "type" => "section"
                   }
                 ]
               }
             } == Jason.decode(body)

      TeslaHelper.response(body: %{"ts" => "1234567890.123456", "channel" => "C12345678"})
    end)

    assert {:ok, _env} = Devhub.Integrations.Slack.query_request(query)
  end
end
