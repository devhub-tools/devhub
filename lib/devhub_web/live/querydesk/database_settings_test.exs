defmodule DevhubWeb.Live.QueryDesk.DatabaseSettingsTest do
  use DevhubWeb.ConnCase, async: true

  import Devhub.QueryDesk.Utils.GetConnectionPid
  import Phoenix.LiveViewTest

  alias Devhub.QueryDesk.RepoRegistry
  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.QueryDesk.Schemas.DatabaseCredential
  alias Devhub.Repo

  setup %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    role = insert(:role, organization: organization)

    conn = get(conn, ~p"/querydesk/databases/#{credential.database.id}")

    assert html_response(conn, 200) =~ "devhub_test"

    {:ok, view, _html} = live(conn)

    %{view: view, credential: credential, role: role, conn: conn}
  end

  test "New database", %{conn: conn} do
    conn = get(conn, ~p"/querydesk/databases/new")

    assert html_response(conn, 302) =~ "/querydesk/databases/db_"
  end

  test "listing databases with agents", %{conn: conn, organization: organization} do
    agent = insert(:agent, organization: organization)

    insert(:database_credential,
      default_credential: true,
      database: build(:database, name: "with agent", organization: organization, agent: agent)
    )

    {:ok, _view, html} = live(conn)

    assert html =~ agent.name
  end

  test "view/update database", %{view: view, credential: credential} do
    {:ok, pid} = get_connection_pid(credential)
    assert [{^pid, _value}] = Registry.lookup(RepoRegistry, credential.id)

    view
    |> element(~s(form[data-testid=database-form]))
    |> render_change(%{
      _target: ["database", "hostname"],
      database: %{hostname: "127.0.0.2"}
    })

    # make sure repo connection was terminated
    assert [] = Registry.lookup(RepoRegistry, credential.id)
  end

  test "test connection", %{view: view} do
    view
    |> element(~s(button[phx-click="test_connection"]))
    |> render_click()

    assert render_async(view) =~ "Connection successful"

    view
    |> element(~s(form[data-testid=database-form]))
    |> render_change(%{
      _target: ["database", "credentials", "0", "username"],
      database: %{
        credentials: %{
          0 => %{username: "wrong"}
        }
      }
    })

    view
    |> element(~s(button[phx-click="test_connection"]))
    |> render_click()

    assert render_async(view) =~ "password authentication failed for user &quot;wrong&quot"
  end

  describe "edit credential" do
    test "edit username", %{view: view, credential: credential} do
      view
      |> element(~s(form[data-testid=database-form]))
      |> render_change(%{
        _target: ["database", "credentials", "0", "username"],
        database: %{
          credentials: %{
            0 => %{id: credential.id, reviews_required: 4},
            1 => %{username: "test", password: "postgres", reviews_required: 0}
          }
        }
      })

      assert %{reviews_required: 4, password: "postgres", default_credential: true} =
               Repo.get(DatabaseCredential, credential.id)

      # make sure repo connection was terminated
      assert [] = Registry.lookup(RepoRegistry, credential.id)
    end

    test "edit default credential", %{view: view, credential: credential} do
      %{database: database} = credential

      view
      |> element(~s(form[data-testid=database-form]))
      |> render_change(%{
        _target: ["database", "credentials", "0", "default_credential"],
        database: %{
          credentials: %{
            0 => %{id: credential.id, reviews_required: 4, default_credential: true},
            1 => %{username: "test", password: "postgres", reviews_required: 0}
          }
        }
      })

      assert %Database{
               credentials: [
                 %DatabaseCredential{reviews_required: 4, password: "postgres", default_credential: true},
                 %DatabaseCredential{reviews_required: 0, password: "postgres", default_credential: false}
               ]
             } = Database |> Repo.get(database.id) |> Repo.preload(:credentials)

      view
      |> element(~s(form[data-testid=database-form]))
      |> render_change(%{
        _target: ["database", "credentials", "1", "default_credential"],
        database: %{
          credentials: %{
            0 => %{id: credential.id, reviews_required: 4, default_credential: false},
            1 => %{username: "test", password: "postgres", reviews_required: 0, default_credential: true}
          }
        }
      })

      assert %Database{
               credentials: [
                 %DatabaseCredential{reviews_required: 4, password: "postgres", default_credential: false},
                 %DatabaseCredential{reviews_required: 0, password: "postgres", default_credential: true}
               ]
             } = Database |> Repo.get(database.id) |> Repo.preload(:credentials)
    end
  end

  test "update without credentials", %{conn: conn, credential: credential} do
    %{database: database} = credential

    Repo.delete(credential, allow_stale: true)

    {:ok, view, _html} = live(conn)

    view
    |> element(~s(form[data-testid=database-form]))
    |> render_change(%{
      _target: ["database", "name"],
      database: %{
        name: "new name"
      }
    })

    assert %Database{
             name: "new name"
           } = Repo.get(Database, database.id)
  end

  describe "delete database" do
    test "successful", %{view: view} do
      assert {:error, {:live_redirect, %{kind: :push, to: "/querydesk"}}} =
               view
               |> element(~s(button[data-testid=delete-database]))
               |> render_click()
    end

    test "failure", %{view: view, credential: credential} do
      %{database: %{id: database_id} = database} = credential
      changeset = Database.changeset(database, %{})

      expect(Devhub.QueryDesk, :delete_database, fn %{id: ^database_id} -> {:error, changeset} end)

      assert view
             |> element(~s(button[data-testid=delete-database]))
             |> render_click() =~ "Failed to delete database."
    end
  end

  test "encryption", %{view: view, credential: credential} do
    view
    |> element(~s(form[data-testid=database-form]))
    |> render_change(%{
      _target: ["database", "ssl"],
      database: %{ssl: "true", cacertfile: "test", certfile: "test", keyfile: "test"}
    })

    assert %{ssl: true, cacertfile: "test", certfile: "test", keyfile: "test"} =
             Repo.get(Database, credential.database.id)

    # if a value is not set it should not override what is saved into database
    view
    |> element(~s(form[data-testid=database-form]))
    |> render_change(%{
      _target: ["database", "ssl"],
      database: %{ssl: "true", cacertfile: "new value", certfile: "", keyfile: ""}
    })

    assert %{ssl: true, cacertfile: "new value", certfile: "test", keyfile: "test"} =
             Repo.get(Database, credential.database.id)

    # another test to hit cacertfile line

    view
    |> element(~s(form[data-testid=database-form]))
    |> render_change(%{
      _target: ["database", "ssl"],
      database: %{ssl: "true", cacertfile: "", certfile: "", keyfile: "new value"}
    })

    assert %{ssl: true, cacertfile: "new value", certfile: "test", keyfile: "new value"} =
             Repo.get(Database, credential.database.id)
  end

  test "fail to save", %{view: view, credential: credential} do
    # failing to update slack
    %{database: %{id: database_id}} = credential

    expect(Devhub.QueryDesk, :update_database, fn %{id: ^database_id} = database,
                                                  %{"name" => "duplicate name"} = params ->
      changeset = Database.changeset(database, params)

      {:error,
       %{
         changeset
         | action: :update,
           errors: [
             name:
               {"that name is already in use",
                [
                  constraint: :unique,
                  constraint_name: "querydesk_databases_organization_id_name_group_index"
                ]}
           ]
       }}
    end)

    assert view
           |> element(~s(form[data-testid=database-form]))
           |> render_change(%{
             _target: ["database", "name"],
             database: %{name: "duplicate name"}
           }) =~ "that name is already in use"
  end
end
