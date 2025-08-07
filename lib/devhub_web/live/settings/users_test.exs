defmodule DevhubWeb.Live.Settings.UsersTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser
  alias Devhub.Users.Team
  alias Devhub.Users.TeamMember

  test "can view page", %{conn: conn, organization: organization} do
    insert(:github_user, organization: organization, username: "Brianna13")
    insert(:linear_user, organization: organization, name: "Brianna St Clair")

    insert(:organization_user,
      organization: organization,
      user: build(:user, name: "Michael St Clair", passkeys: [build(:passkey)]),
      github_user: build(:github_user, organization: organization, username: "michaelst"),
      linear_user: build(:linear_user, organization: organization, name: "Michael")
    )

    conn = get(conn, "/settings/users")

    assert html_response(conn, 200)

    {:ok, view, html} = live(conn)

    assert html =~ "Michael St Clair"
    assert html =~ "Brianna St Clair"
    assert html =~ "Brianna13"

    # open user modal
    assert [
             {"button",
              [
                {"class", _class},
                {"phx-click", "show_user_modal"},
                {"phx-value-id", modal_id}
              ], _children}
             | _rest
           ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()
  end

  test "can merge integration users", %{conn: conn, organization: organization, user: user} do
    %{organization_users: [%{id: org_user_id}]} = user

    %{id: github_user_id} = insert(:github_user, organization: organization, username: "Brianna13")
    %{id: linear_user_id} = insert(:linear_user, organization: organization, name: "Brianna St Clair")

    assert {:ok, view, html} = live(conn, ~p"/settings/users")

    # open user modal
    [
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    render_hook(view, "select_linear_user", %{id: linear_user_id})
    org_user = Repo.get(OrganizationUser, org_user_id)
    assert org_user.linear_user_id == linear_user_id

    render_hook(view, "select_github_user", %{id: github_user_id})
    org_user = Repo.get(OrganizationUser, org_user_id)
    assert org_user.github_user_id == github_user_id
  end

  test "handles failure on merging users", %{conn: conn, organization: organization} do
    github_user = insert(:github_user, organization: organization, username: "Brianna13")
    linear_user = insert(:linear_user, organization: organization, name: "Michael")

    %{linear_user_id: linear_user_id} =
      insert(:organization_user, organization: organization, linear_user: linear_user)

    %{github_user_id: github_user_id} =
      insert(:organization_user, organization: organization, github_user: github_user)

    assert {:ok, view, html} = live(conn, ~p"/settings/users")

    # open user modal
    [
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    # failure on linear user

    expect(Devhub.Users, :merge, fn _selected_organization_user, _linear_organization_user ->
      {:error, :cannot_merge}
    end)

    html = render_hook(view, "select_linear_user", %{id: linear_user_id})
    assert html =~ "Failed to merge users"

    # open user modal
    [
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    # failure on github user
    expect(Devhub.Users, :merge, fn _selected_organization_user, _github_organization_user -> {:error, :cannot_merge} end)
    assert render_hook(view, "select_github_user", %{id: github_user_id}) =~ "Failed to merge users"
  end

  test "filter users", %{conn: conn, organization: organization} do
    insert(:linear_user, organization: organization, name: "Michael")
    insert(:linear_user, organization: organization, name: "Brianna")
    insert(:github_user, organization: organization, username: "michaelst")
    insert(:github_user, organization: organization, username: "briannast")

    assert {:ok, view, html} = live(conn, ~p"/settings/users")

    # open user modal
    [
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    refute html =~ "Manage teams"

    html =
      view
      |> element(~s(button[phx-value-id=#{modal_id}]))
      |> render_click()
      |> Floki.parse_fragment!()

    # testing its filtering users correctly
    assert html |> Floki.find("#user-modal-content") |> Floki.text() =~ "Manage teams"
    assert html |> Floki.find("#user-modal-content") |> Floki.text() =~ "Michael"
    assert html |> Floki.find("#user-modal-content") |> Floki.text() =~ "Brianna"

    html = view |> render_hook("filter_linear_users", %{name: "Brianna"}) |> Floki.parse_fragment!()
    refute html |> Floki.find("#user-modal-content") |> Floki.text() =~ "Michael"
    assert html |> Floki.find("#user-modal-content") |> Floki.text() =~ "Brianna"

    assert html |> Floki.find("#user-modal-content") |> Floki.text() =~ "michaelst"
    assert html |> Floki.find("#user-modal-content") |> Floki.text() =~ "briannast"

    html = view |> render_hook("filter_github_users", %{name: "br"}) |> Floki.parse_fragment!()
    refute html |> Floki.find("#user-modal-content") |> Floki.text() =~ "michaelst"
    assert html |> Floki.find("#user-modal-content") |> Floki.text() =~ "briannast"

    html = view |> render_hook("clear_filter") |> Floki.parse_fragment!()
    assert html |> Floki.find("#user-modal-content") |> Floki.text() =~ "michaelst"
    assert html |> Floki.find("#user-modal-content") |> Floki.text() =~ "briannast"
  end

  test "team flow", %{conn: conn, organization: organization, user: user} do
    %{organization_users: [%{id: org_user_id}]} = user
    %{id: team_id} = insert(:team, organization: organization)

    assert {:ok, view, html} = live(conn, ~p"/settings/users")

    # open user modal
    [
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    refute html =~ "Done"

    assert view
           |> element(~s(button[phx-click=manage_teams]))
           |> render_click() =~ "Done"

    view
    |> element(~s(button[phx-click=add_to_team]))
    |> render_click()

    # make sure user is added to team
    assert %Team{
             team_members: [
               %TeamMember{organization_user_id: ^org_user_id}
             ]
           } =
             Team |> Repo.get(team_id) |> Repo.preload(:team_members)

    html =
      view
      |> element(~s(button[phx-click=remove_from_team]))
      |> render_click()

    # make sure user is removed from team
    assert %Team{
             team_members: []
           } =
             Team |> Repo.get(team_id) |> Repo.preload(:team_members)

    assert html =~ "Done"

    refute view
           |> element(~s(button[phx-click=done_managing_teams]))
           |> render_click() =~ "Done"
  end

  test "user connected to no teams", %{conn: conn} do
    assert {:ok, view, html} = live(conn, ~p"/settings/users")

    # open user modal
    [
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    # manage teams
    html =
      view
      |> element(~s(button[phx-click=manage_teams]))
      |> render_click()

    assert html =~ "Create a team"

    assert {:error, {:redirect, %{to: "/settings/teams"}}} =
             view
             |> element(~s(a[data-testid=create-team]))
             |> render_click()
  end

  test "update organization user", %{conn: conn, organization: organization, user: user} do
    %{organization_users: [%{id: org_user2_id}]} = user

    %{id: org_user_id} =
      insert(:organization_user,
        organization: organization,
        user: build(:user, name: "Michael St Clair", passkeys: [build(:passkey)]),
        github_user: build(:github_user, organization: organization, username: "michaelst"),
        linear_user: build(:linear_user, organization: organization, name: "Michael"),
        permissions: %{super_admin: false, manager: false, billing_admin: false},
        legal_name: "Aubrey Plaza"
      )

    assert {:ok, view, html} = live(conn, ~p"/settings/users")

    # open user modal
    [
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    # getting permissions before update
    assert %OrganizationUser{permissions: %{super_admin: true, manager: false, billing_admin: false}} =
             Repo.get(OrganizationUser, org_user2_id)

    view
    |> element(~s(form[phx-change=update_organization_user]))
    |> render_change(%{
      "organization_user" => %{
        "permissions" => %{
          "billing_admin" => "true",
          "manager" => "true",
          "super_admin" => "true"
        }
      }
    })

    # making sure permissions are updated on correct user
    assert [
             %OrganizationUser{
               id: ^org_user_id,
               permissions: %{super_admin: false, manager: false, billing_admin: false}
             },
             %OrganizationUser{
               id: ^org_user2_id,
               permissions: %{super_admin: true, manager: true, billing_admin: true}
             }
           ] = OrganizationUser |> Repo.all() |> Enum.sort_by(& &1.legal_name)
  end

  test "archive", %{conn: conn} do
    assert {:ok, view, html} = live(conn, ~p"/settings/users")

    # open user modal
    [
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    # throwing in hide user modal test into test flow

    refute render_hook(view, "hide_user_modal") =~ "Archive"

    html = render(view)

    # open user modal
    [
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    # archive
    assert view
           |> element(~s(button[phx-click=archive]))
           |> render_click() =~ "Unarchive"

    # unarchive
    refute view
           |> element(~s(button[phx-click=unarchive]))
           |> render_click() =~ "Unarchive"
  end

  test "archive imported user", %{conn: conn, organization: organization} do
    %{id: linear_user_id} = insert(:linear_user, organization: organization, name: "Michael")
    insert(:organization_user, organization: organization, linear_user_id: linear_user_id)
    changeset = OrganizationUser.changeset(%{})

    assert {:ok, view, html} = live(conn, ~p"/settings/users")

    # open user modal

    [
      _user_button,
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
      | _rest
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    # failure
    expect(Devhub.Users, :update_organization_user, fn _organization_user, _attrs -> {:error, changeset} end)

    view
    |> element(~s(button[phx-click=archive]))
    |> render_click() =~ "Failed to archive user"

    html = render(view)

    # open user modal
    [
      _user_button,
      {"button",
       [
         {"class", _class},
         {"phx-click", "show_user_modal"},
         {"phx-value-id", modal_id}
       ], _children}
    ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

    view
    |> element(~s(button[phx-value-id=#{modal_id}]))
    |> render_click()

    # archive success
    assert view
           |> element(~s(button[phx-click=archive]))
           |> render_click() =~ "Unarchive"
  end

  test "invite new user", %{conn: conn} do
    changeset = OrganizationUser.changeset(%{})
    assert {:ok, view, _html} = live(conn, ~p"/settings/users")

    # failure case
    expect(Devhub.Users, :create_organization_user, fn _params -> {:error, changeset} end)

    assert view
           |> element(~s(form[data-testid=invite_new_user_form]))
           |> render_submit(%{name: "Blaze", email: "Blaze13@gmail.com"}) =~ "Failed to invite user"

    # success case
    assert {:error, {:live_redirect, %{kind: :push, to: "/settings/users"}}} =
             view
             |> element(~s(form[data-testid=invite_new_user_form]))
             |> render_submit(%{name: "Blaze", email: "Blaze13@gmail.com"})
  end

  describe "invite imported user" do
    test "success", %{conn: conn, organization: organization} do
      insert(:linear_user, organization: organization, name: "Michael")

      assert {:ok, view, html} = live(conn, ~p"/settings/users")

      # open user modal
      [
        _user_button,
        {"button",
         [
           {"class", _class},
           {"phx-click", "show_user_modal"},
           {"phx-value-id", modal_id}
         ], _children}
      ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

      assert view
             |> element(~s(button[phx-value-id=#{modal_id}]))
             |> render_click()

      # open up form
      view
      |> element(~s(button[phx-click=start_invite]))
      |> render_click()

      # making sure its directing to invite modal
      refute has_element?(view, ~s(button[phx-click=start_invite]))

      # testing cancel button in flow
      view
      |> element(~s(button[phx-click=cancel_invite]))
      |> render_click()

      assert has_element?(view, ~s(button[phx-click=start_invite]))
      # reopen form
      view
      |> element(~s(button[phx-click=start_invite]))
      |> render_click()

      refute has_element?(view, ~s(button[phx-click=start_invite]))

      assert view
             |> element(~s(form[phx-submit="send_invite"))
             |> render_submit(%{name: "Michael", email: "michaelst@gmail.com"}) =~ "User invite created"
    end

    test "failure", %{conn: conn, organization: organization} do
      insert(:linear_user, organization: organization, name: "Michael")

      changeset = OrganizationUser.changeset(%{})
      assert {:ok, view, html} = live(conn, ~p"/settings/users")

      # open user modal
      [
        _user_button,
        {"button",
         [
           {"class", _class},
           {"phx-click", "show_user_modal"},
           {"phx-value-id", modal_id}
         ], _children}
      ] = html |> Floki.parse_fragment!() |> Floki.find("[phx-click=show_user_modal]")

      view
      |> element(~s(button[phx-value-id=#{modal_id}]))
      |> render_click()

      expect(Devhub.Users, :invite_user, fn _organization_user, _name, _email -> {:error, changeset} end)

      view
      |> element(~s(button[phx-click=start_invite]))
      |> render_click()

      assert view
             |> element(~s(form[phx-submit="send_invite"))
             |> render_submit(%{name: "Michael", email: "michaelst@gmail.com"}) =~ "Failed to invite user"
    end
  end
end
