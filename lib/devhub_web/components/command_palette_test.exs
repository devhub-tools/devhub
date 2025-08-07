defmodule DevhubWeb.Components.CommandPaletteTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "searches tables on query view", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    insert(:database_column, database: credential.database, organization: organization, table: "users", name: "id")

    assert {:ok, view, _html} =
             live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    html =
      view
      |> element(~s(form[phx-change=search]))
      |> render_change(%{"search" => "users"})

    assert [
             {"a",
              [
                {"href", "/querydesk/databases/#{credential.database_id}/table/users"},
                {"data-phx-link", "redirect"},
                {"data-phx-link-state", "push"},
                {"id", "option-users"},
                {"role", "option"},
                {"class",
                 "list-nav-item group flex cursor-pointer select-none items-center rounded-xl p-3 hover:bg-alpha-4 focus:bg-alpha-4 focus:outline-none"},
                {"tabindex", "-1"}
              ],
              [
                {"span", [{"class", "devhub-querydesk size-6"}], []},
                {"div", [{"class", "flex h-10 w-full items-center justify-between"}],
                 [
                   {"div", [{"class", "ml-4 flex-auto"}],
                    [
                      {"span",
                       [
                         {"class", "flex items-center gap-x-1 text-sm font-medium text-gray-700"}
                       ], ["\n                users\n                \n              "]}
                    ]},
                   {"div", [{"class", "text-alpha-64 text-xs"}], ["\n              Table\n            "]}
                 ]}
              ]}
           ] ==
             html
             |> Floki.parse_document!()
             |> Floki.find("#option-users")
  end
end
