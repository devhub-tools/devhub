defmodule Devhub.QueryDesk.Actions.CreateQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Query

  test "create_query/1" do
    organization = insert(:organization)
    credential = insert(:database_credential, database: build(:database, organization: organization))

    assert {:ok, %Query{slack_message_ts: nil, slack_channel: nil}} =
             QueryDesk.create_query(%{
               query: "SELECT * FROM schema_migrations LIMIT 500;",
               organization_id: organization.id,
               credential_id: credential.id
             })
  end

  test "sends slack notification when reviews are required" do
    organization = insert(:organization)
    user = insert(:user, name: "John Doe")

    insert(:integration,
      organization: organization,
      provider: :slack,
      access_token: Jason.encode!(%{bot_token: "xoxb-1234567890"})
    )

    credential =
      insert(:database_credential,
        reviews_required: 1,
        database:
          build(:database,
            organization: organization,
            slack_channel: "#alerts"
          )
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
                 "channel" => "#alerts",
                 "thread_ts" => nil,
                 "attachments" => [
                   %{
                     "blocks" => [
                       %{
                         "text" => %{"text" => "```SELECT * FROM schema_migrations LIMIT 500;```", "type" => "mrkdwn"},
                         "type" => "section"
                       },
                       %{
                         "text" => %{
                           "text" => "<http://localhost:4002/querydesk/pending-queries?query_id=" <> _rest,
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
             } = Jason.decode(body)

      TeslaHelper.response(body: %{"ts" => "1234567890.123456", "channel" => "C12345678"})
    end)

    assert {:ok, %Query{slack_message_ts: "1234567890.123456", slack_channel: "C12345678"}} =
             QueryDesk.create_query(%{
               query: "SELECT * FROM schema_migrations LIMIT 500;",
               organization_id: organization.id,
               credential_id: credential.id,
               user_id: user.id
             })
  end
end
