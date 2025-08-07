defmodule DevhubWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DevhubWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Devhub.Factory

  using do
    quote do
      use DevhubWeb, :verified_routes
      use Mimic
      use Oban.Testing, repo: Devhub.Repo

      # Import conveniences for testing with connections
      import Devhub.Factory
      import DevhubWeb.ConnCase
      import Phoenix.ConnTest
      import Plug.Conn

      # The default endpoint for testing
      @endpoint DevhubWeb.Endpoint

      setup :verify_on_exit!
    end
  end

  setup tags do
    Devhub.DataCase.setup_sandbox(tags)
    Mimic.stub(Tesla.Adapter.Finch)
    Mimic.stub(OpenIDConnect)

    organization = insert(:organization, license: %{plan: tags[:with_plan] || :querydesk})

    if tags[:unauthenticated] do
      conn = Phoenix.ConnTest.build_conn()

      {:ok, conn: conn, organization: organization}
    else
      permissions = tags[:with_permissions] || %{super_admin: true}

      user =
        insert(:user,
          provider: "github",
          # the license has this external_id as a seat
          external_id: organization.id,
          organization_users: [
            build(:organization_user,
              organization: organization,
              permissions: permissions,
              legal_name: "Michael St Clair"
            )
          ]
        )

      mfa_at =
        if tags[:with_mfa] do
          insert(:passkey, user: user)
          DateTime.utc_now()
        end

      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Test.init_test_session(%{mfa_at: mfa_at})
        |> Plug.Conn.put_session(:user_id, user.id)
        |> Plug.Conn.assign(:organization, organization)

      {:ok, conn: conn, user: user, organization: organization}
    end
  end
end
