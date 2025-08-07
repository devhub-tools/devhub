defmodule DevHubWeb.Live.Settings.IcalTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Integrations.Schemas.Ical
  alias Devhub.Repo
  alias Tesla.Adapter.Finch

  @tag with_plan: :scale
  test "create", %{conn: conn, organization: organization} do
    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/ical")

    # failure case
    assert view
           |> element(~s(form[phx-submit=create_integration]))
           |> render_submit(%{
             "ical" => %{
               link: "http://dafdfadf",
               title: "",
               color: "blue",
               organization_id: organization.id
             }
           }) =~ "can&#39;t be blank"

    # success case
    assert {:error, {:live_redirect, %{kind: :push, to: "/settings/integrations/ical"}}} =
             view
             |> element(~s(form[phx-submit=create_integration]))
             |> render_submit(%{
               "ical" => %{
                 link: "http://dafdfadf",
                 title: "event",
                 color: "blue",
                 organization_id: organization.id
               }
             })
  end

  @tag with_plan: :scale
  test "update", %{conn: conn, organization: organization} do
    %{id: ical_id} = insert(:ical, organization: organization)

    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/ical")

    # failure case

    view
    |> element(~s(div[phx-click=edit_integration"]))
    |> render_click()

    assert view
           |> element(~s(form[phx-submit=update_integration]))
           |> render_submit(%{
             "ical" => %{
               link: "http://dafdfadf",
               title: "",
               color: "red"
             }
           }) =~ "can&#39;t be blank"

    # success case
    view
    |> element(~s(div[phx-click=edit_integration"]))
    |> render_click()

    assert {:error, {:live_redirect, %{kind: :push, to: "/settings/integrations/ical"}}} =
             view
             |> element(~s(form[phx-submit=update_integration]))
             |> render_submit(%{
               "ical" => %{
                 link: "http://dafdfadf",
                 title: "event",
                 color: "blue"
               }
             })

    # checking color of ical in the database was updated
    [%{id: ^ical_id, color: "blue"}] = Repo.all(Ical)
  end

  @tag with_plan: :scale
  test "delete", %{conn: conn, organization: organization} do
    %{id: ical_id} = insert(:ical, organization: organization)
    changeset = Ical.changeset(%{})

    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/ical")

    # checking ical in the database
    assert [%{id: ^ical_id}] = Repo.all(Ical)

    # failure case
    expect(Devhub.Integrations, :delete_ical, fn _integration ->
      {:error, changeset}
    end)

    assert view
           |> element(~s(button[phx-click="delete_integration"]))
           |> render_click() =~ "Failed to delete iCal integration"

    # success case
    assert {:error, {:live_redirect, %{kind: :push, to: "/settings/integrations/ical"}}} =
             view
             |> element(~s(button[phx-click="delete_integration"]))
             |> render_click()

    # checking ical in the database was deleted
    [] = Repo.all(Ical)
  end

  @tag with_plan: :scale
  test "sync calendar", %{conn: conn, organization: organization} do
    insert(:ical, organization: organization)

    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/ical")

    # sync calendar
    expect(Finch, :call, fn %Tesla.Env{
                              method: :get,
                              url:
                                "https://www.google.com/calendar/ical/en.usa%40holiday.calendar.google.com/public/basic.ics"
                            },
                            _opts ->
      TeslaHelper.response(body: "")
    end)

    assert view
           |> element(~s(div[phx-click=sync_calendar"]))
           |> render_click() =~ "Syncing calendar..."
  end

  test "cancel edit", %{conn: conn, organization: organization} do
    insert(:ical, organization: organization)

    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/ical")

    assert view
           |> element(~s(div[phx-click=edit_integration"]))
           |> render_click() =~ "Edit iCal Integration"

    refute render_hook(view, "cancel_edit") =~ "Edit iCal Integration"
  end
end
