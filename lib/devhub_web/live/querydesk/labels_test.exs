defmodule DevhubWeb.Live.QueryDesk.LabelsTest do
  @moduledoc false
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Repo
  alias Devhub.Shared
  alias Devhub.Shared.Schemas.Label

  test "no data", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/querydesk/labels")

    assert html =~ "Labels"
    assert html =~ "Add Label"
  end

  test "add label", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/querydesk/labels")

    # modal is not open
    refute has_element?(view, ~s(#label-modal))

    # no icons are displayed because there are no labels
    refute has_element?(view, ~s(div[data-testid="edit-icon"]))

    # opening the modal
    view
    |> element(~s(button[phx-click="add_label"]))
    |> render_click()

    # making sure the modal is open
    assert has_element?(view, ~s(#label-modal))

    # submitting the form
    html =
      view
      |> element(~s(form[phx-submit="save"]))
      |> render_submit(%{label: %{name: "test"}})

    # label name and icons are displayed on page
    assert html =~ "test"
    assert has_element?(view, ~s(button[data-testid="edit-icon"]))

    # modal is closed
    refute has_element?(view, ~s(#label-modal))
  end

  test "edit label", %{conn: conn, organization: organization} do
    changeset = Label.changeset(%Label{}, %{})
    insert(:label, organization: organization)
    {:ok, view, _html} = live(conn, ~p"/querydesk/labels")

    # open modal
    view
    |> element(~s(button[phx-click="edit_label"]))
    |> render_click()

    # updated color through color input on form
    html =
      view
      |> element(~s(form[phx-change="update_changeset"]))
      |> render_change(%{label: %{color: "#000000"}})

    # checking hex code value is updated
    assert [
             _input,
             {"input",
              [
                {"type", "color"},
                {"name", "label[color]"},
                {"id", "label_color"},
                {"value", "#000000"},
                {"class",
                 "-mt-[0.25rem] -mx-[0.125rem] w-[calc(100%+0.25rem)] h-10 cursor-pointer border-none bg-transparent p-0"}
              ], []}
           ] = html |> Floki.parse_fragment!() |> Floki.find(~s(form[data-testid="label-form"] input))

    # updating color through button for preset colors
    view
    |> element(~s(button[phx-click="edit_label"]))
    |> render_click()

    html =
      view
      |> element(~s(button[phx-click="select_color"][phx-value-color="#c2410c"]))
      |> render_click()

    # checking color got updated
    assert [
             _input,
             {"input",
              [
                {"type", "color"},
                {"name", "label[color]"},
                {"id", "label_color"},
                {"value", "#c2410c"},
                {"class",
                 "-mt-[0.25rem] -mx-[0.125rem] w-[calc(100%+0.25rem)] h-10 cursor-pointer border-none bg-transparent p-0"}
              ], []}
           ] = html |> Floki.parse_fragment!() |> Floki.find(~s(form[data-testid="label-form"] input))

    # save label
    view
    |> element(~s(form[#label-modal phx-submit="save"]))
    |> render_submit()

    # failed to save label
    view
    |> element(~s(button[phx-click="add_label"]))
    |> render_click()

    assert view
           |> element(~s(form[#label-modal phx-submit="save"]))
           |> render_submit() =~ "Failed to save label"

    # check label is in repo
    assert [label] = Repo.all(Label)
    assert label.name == "testing"
    assert label.color == "#c2410c"

    # failed to delete label
    expect(Shared, :delete_label, fn _label -> {:error, changeset} end)

    assert view
           |> element(~s(button[phx-click="delete_label"]))
           |> render_click() =~ "Failed to delete label"

    # delete label
    view
    |> element(~s(button[phx-click="delete_label"]))
    |> render_click()

    # check label is deleted
    refute Repo.get(Label, label.id)
  end

  test "close modal", %{conn: conn, organization: organization} do
    insert(:label, organization: organization)

    {:ok, view, _html} = live(conn, ~p"/querydesk/labels")

    view
    |> element(~s(button[phx-click="add_label"]))
    |> render_click()

    assert(has_element?(view, ~s(#label-modal)))

    view
    |> element(~s(button[phx-click="clear_changeset"]))
    |> render_click()

    refute has_element?(view, ~s(#label-modal))
  end
end
