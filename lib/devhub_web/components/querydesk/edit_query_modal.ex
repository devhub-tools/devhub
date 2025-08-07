defmodule DevhubWeb.Components.Querydesk.EditQueryModal do
  @moduledoc false
  use DevhubWeb, :html

  def edit_query_modal(assigns) do
    ~H"""
    <.modal id="edit-query-modal" show={true} on_cancel={JS.push("clear_query")}>
      <div>
        <div class="mb-6 text-center">
          <h3 class="text-base font-semibold text-gray-900" id="modal-title">
            Edit query
          </h3>
        </div>
      </div>
      <.form
        :let={f}
        for={@query_changeset}
        phx-change="update_query_changeset"
        phx-submit="save_query"
        class="focus-on-show flex flex-col gap-y-4"
      >
        <.input field={f[:query]} type="textarea" />
        <.input
          :if={not String.contains?(String.downcase(f[:query].value), "limit")}
          field={f[:limit]}
          type="text"
          label="Limit"
        />
        <.input field={f[:timeout]} type="text" label="Timeout (seconds)" />
        <.input
          field={f[:credential_id]}
          type="select"
          options={
            Enum.map(@query_changeset.data.credential.database.credentials, &{&1.username, &1.id})
          }
          label="Run as"
        />
        <% credential =
          Enum.find(
            @query_changeset.data.credential.database.credentials,
            &(&1.id == f[:credential_id].value)
          ) %>
        <p class="text-alpha-64 -mt-2 text-xs">
          {pluralize_unit(credential.reviews_required, "review")} required
        </p>
        <.input
          :if={credential.reviews_required > 0}
          field={f[:run_on_approval]}
          type="toggle"
          label="Run automatically on approval"
        />

        <div class="mt-6 sm:grid sm:grid-flow-row-dense sm:grid-cols-2 sm:gap-4">
          <.button
            type="button"
            variant="secondary"
            phx-click={JS.exec("data-cancel", to: "#edit-query-modal")}
            aria-label={gettext("close")}
          >
            Cancel
          </.button>
          <.button type="submit" variant="primary">Save</.button>
        </div>
      </.form>
    </.modal>
    """
  end
end
