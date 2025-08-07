defmodule DevhubWeb.Live.Portal.PlanningTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Calendar.Event
  alias Devhub.Repo

  test "loads with no data", %{conn: conn} do
    assert {:ok, view, _html} = live(conn, ~p"/portal/planning")

    assert has_element?(view, ~s(div[data-testid="calendar"]))
  end

  test "calendar flow", %{organization: organization, conn: conn} do
    org_user = insert(:organization_user, organization: organization)
    linear_user = insert(:linear_user, organization_user: org_user, organization: organization)

    start_date = Timex.beginning_of_week(DateTime.utc_now())
    end_date = DateTime.add(start_date, 2, :day)
    insert(:event, organization: organization, linear_user: linear_user, start_date: start_date, end_date: end_date)

    assert {:ok, view, html} = live(conn, ~p"/portal/planning")

    # getting event out of view to test today button

    assert html =~ "OOO"

    refute view
           |> element(~s(button[phx-click=next_week]))
           |> render_click() =~ "OOO"

    # today button being pressed
    assert view
           |> element(~s(button[phx-click=back_to_today]))
           |> render_click() =~ "OOO"

    Enum.each(1..4, fn _i ->
      assert view
             |> element(~s(button[phx-click=previous_week]))
             |> render_click() =~ "OOO"
    end)

    refute view
           |> element(~s(button[phx-click=previous_week]))
           |> render_click() =~ "OOO"

    # today button being pressed after going previous
    assert view
           |> element(~s(button[phx-click=back_to_today]))
           |> render_click() =~ "OOO"

    assert view
           |> render()
           |> Floki.parse_document!()
           |> Floki.find(~s(div[data-testid="columns"]))
           |> length() == 5

    # timeline update
    assert view
           |> element(~s(form[phx-change=update_timeline]))
           |> render_change(%{timeline: "quarter"})
           |> Floki.parse_document!()
           |> Floki.find(~s(div[data-testid="columns"]))
           |> length() == 12
  end

  @tag with_permissions: %{manager: true}
  test "priority flow", %{organization: organization, conn: conn} do
    org_user = insert(:organization_user, organization: organization)
    linear_user = insert(:linear_user, organization_user: org_user, organization: organization)
    project = insert(:project, organization: organization)

    assert {:ok, view, _html} = live(conn, ~p"/portal/planning")

    # opening modal and adding priority
    view
    |> element(~s(button[phx-click=show_create_event_modal]))
    |> render_click()

    render_hook(view, "select_project", %{id: project.id})
    render_hook(view, "select_user", %{id: linear_user.id})

    assert view
           |> element(~s(form[phx-submit=add_priority]))
           |> render_submit(%{
             "event" => %{
               "color" => "blue",
               "start_date" => Date.utc_today(),
               "end_date" => Date.add(Date.utc_today(), 7)
             }
           }) =~ project.name

    assert_patched(view, ~p"/portal/planning")

    [event] = Repo.all(Event)
    assert event.title == project.name
    assert event.color == "blue"
    assert event.start_date == Date.utc_today()
    assert event.end_date == Date.add(Date.utc_today(), 7)

    # opening up event and updating
    view
    |> element(~s(button[phx-value-event_id=#{event.id}]))
    |> render_click()

    view
    |> element(~s(form[phx-submit=update_priority]))
    |> render_submit(%{"event" => %{"color" => "gray"}})

    [event] = Repo.all(Event)
    assert event.title == project.name
    assert event.color == "gray"

    # deleting event
    view
    |> element(~s(button[phx-value-event_id=#{event.id}]))
    |> render_click()

    view
    |> element(~s(button[phx-click=delete_priority]))
    |> render_click()

    [] = Repo.all(Event)

    # adding event fails because project and user aren't set

    view
    |> element(~s(button[phx-click=show_create_event_modal]))
    |> render_click()

    view
    |> element(~s(form[phx-submit=add_priority]))
    |> render_submit(%{
      "event" => %{
        "color" => "blue",
        "start_date" => Date.utc_today(),
        "end_date" => Date.add(Date.utc_today(), 7)
      }
    })

    assert has_element?(view, ~s(form[phx-submit="add_priority"]))

    [] = Repo.all(Event)

    render_hook(view, "cancel")

    refute has_element?(view, ~s(form[phx-submit="add_priority"]))
  end

  @tag with_permissions: %{manager: true}
  test "filter users and projects", %{conn: conn, organization: organization} do
    insert(:linear_user, organization: organization, name: "Brianna")
    insert(:linear_user, organization: organization, name: "Michael")
    insert(:project, organization: organization, name: "Something named different")
    insert(:project, organization: organization, name: "Not the project")

    assert {:ok, view, _html} = live(conn, ~p"/portal/planning")

    html =
      view
      |> element(~s(button[phx-click=show_create_event_modal]))
      |> render_click()
      |> Floki.parse_fragment!()

    # users

    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Brianna"
    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Michael"

    html = view |> render_hook("filter_users", %{name: "br"}) |> Floki.parse_fragment!()

    refute html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Michael"
    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Brianna"

    html = view |> render_hook("clear_filter") |> Floki.parse_fragment!()
    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Brianna"
    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Michael"

    # projects

    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Something named different"
    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Not the project"

    html = view |> render_hook("filter_projects", %{name: "Not the"}) |> Floki.parse_fragment!()
    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Not the project"
    refute html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Something named different"

    html = view |> render_hook("clear_filter") |> Floki.parse_fragment!()
    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Not the project"
    assert html |> Floki.find("#add-priority-content") |> Floki.text() =~ "Something named different"
  end

  @tag with_permissions: %{manager: true}
  test "custom project", %{organization: organization, conn: conn} do
    org_user = insert(:organization_user, organization: organization)
    linear_user = insert(:linear_user, organization_user: org_user, organization: organization)

    assert {:ok, view, _html} = live(conn, ~p"/portal/planning")

    assert view
           |> element(~s(button[phx-click=show_create_event_modal]))
           |> render_click() =~ "Add"

    render_hook(view, "select_project", %{id: "custom:My project"})
    render_hook(view, "select_user", %{id: linear_user.id})

    assert view
           |> element(~s(form[phx-submit=add_priority]))
           |> render_submit(%{
             "event" => %{
               "color" => "blue",
               "start_date" => Date.utc_today(),
               "end_date" => Date.add(Date.utc_today(), 7)
             }
           }) =~ "My project"

    assert_patched(view, ~p"/portal/planning")

    [event] = Repo.all(Event)
    assert event.title == "My project"
    assert event.color == "blue"
    assert event.start_date == Date.utc_today()
    assert event.end_date == Date.add(Date.utc_today(), 7)
  end

  @tag with_permissions: %{manager: true}
  test "user name hierarchy", %{conn: conn, organization: organization} do
    # organization user legal name should trump linear user name
    linear_user = insert(:linear_user, organization: organization, name: "bri")

    insert(:organization_user,
      organization: organization,
      linear_user: linear_user,
      legal_name: "brianna st clair"
    )

    start_date = Timex.beginning_of_week(DateTime.utc_now())
    end_date = DateTime.add(start_date, 7, :day)

    %{id: event1_id} =
      insert(:event,
        organization: organization,
        linear_user: linear_user,
        title: "vacation",
        person: "bri",
        external_id: "1",
        start_date: start_date,
        end_date: end_date
      )

    # if no organization user, linear user name is used

    %{id: linear_user2_id} = insert(:linear_user, organization: organization, name: "michael")

    start_date = Timex.beginning_of_week(DateTime.utc_now())
    end_date = DateTime.add(start_date, 7, :day)

    %{id: event2_id} =
      insert(:event,
        organization: organization,
        title: "meeting",
        person: "michael",
        external_id: "2",
        linear_user_id: linear_user2_id,
        start_date: start_date,
        end_date: end_date
      )

    # if event is not assigned, will assign to organization_user if legal name is the same as person

    start_date = DateTime.utc_now() |> DateTime.add(7, :day) |> Timex.beginning_of_week()
    end_date = DateTime.add(start_date, 7, :day)

    %{id: event3_id} =
      insert(:event,
        organization: organization,
        person: "brianna st clair",
        external_id: "3",
        start_date: start_date,
        end_date: end_date
      )

    assert {:ok, _view, html} = live(conn, ~p"/portal/planning")

    # testing events are in the right grid-row (displaying under the right user)

    assert [
             {"ol", _ol_attrs,
              [
                {"li", [_list1_class, {"style", "grid-row: 2 / span 1; grid-column: 1 / span 7"}],
                 [
                   {"button", [_button1_phx_click, {"phx-value-event_id", ^event2_id}, _button1_class], [_event2_details]}
                 ]},
                {"li", [_list2_class, {"style", "grid-row: 3 / span 1; grid-column: 1 / span 7"}],
                 [
                   {"button", [_button2_phx_click, {"phx-value-event_id", ^event1_id}, _button2_class], [_event1_details]}
                 ]},
                {"li", [_list3_class, {"style", "grid-row: 3 / span 1; grid-column: 8 / span 7"}],
                 [
                   {"button", [_button3_phx_click, {"phx-value-event_id", ^event3_id}, _button3_class], [_event3_details]}
                 ]}
              ]}
           ] = html |> Floki.parse_fragment!() |> Floki.find(~s(ol[data-testid="user_events"]))
  end
end
