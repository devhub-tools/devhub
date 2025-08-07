defmodule DevhubWeb.Components.Querydesk.RunQueryModal do
  @moduledoc false
  use DevhubWeb, :html

  def run_query_modal(assigns) do
    ~H"""
    <.modal id="run-query-modal" show={true} on_cancel={JS.push("clear_query")}>
      <div>
        <div class="mb-6 text-center">
          <h3 class="text-base font-semibold text-gray-900" id="modal-title">
            Run query
          </h3>
        </div>
      </div>
      <.form
        :let={f}
        for={@query_changeset}
        phx-change="update_query_options"
        phx-submit="run_query_with_options"
        class="focus-on-show flex flex-col gap-y-4"
      >
        <%= if @number_of_queries == 1 do %>
          <.input type="hidden" field={f[:query]} />
          <code class="bg-surface-3 max-h-48 overflow-auto break-all rounded p-4">
            <pre
              id="run-query-modal-query"
              phx-hook="SqlHighlight"
              data-query={f[:query].value}
              data-adapter={@database.adapter}
            />
          </code>
        <% else %>
          <div class="w-fit">
            <.badge label={"#{@number_of_queries} selected queries"} color="blue" />
          </div>
        <% end %>
        <.input field={f[:limit]} type="text" label="Default limit" />
        <.input field={f[:timeout]} type="text" label="Timeout (seconds)" />
        <.input
          field={f[:credential_id]}
          type="select"
          options={Enum.map(@database.credentials, &{&1.username, &1.id})}
          label="Run as"
        />
        <% credential = Enum.find(@database.credentials, &(&1.id == f[:credential_id].value)) %>
        <p class="text-alpha-64 -mt-2 text-xs">
          {pluralize_unit(credential.reviews_required, "review")} required
        </p>
        <.input
          :if={credential.reviews_required > 0 and f[:analyze].value not in ["true", true]}
          field={f[:run_on_approval]}
          type="toggle"
          label="Run automatically on approval"
        />
        <.input
          field={f[:analyze]}
          type="toggle"
          label="Analyze query"
          tooltip="If this setting is enabled a query plan will be generated instead of showing results."
        />

        <div class="mt-6 sm:grid sm:grid-flow-row-dense sm:grid-cols-2 sm:gap-4">
          <.button
            type="button"
            variant="secondary"
            phx-click={JS.exec("data-cancel", to: "#run-query-modal")}
            aria-label={gettext("close")}
          >
            Cancel
          </.button>
          <.button type="submit" variant="primary">
            {submit_text(credential, f)}
          </.button>
        </div>
      </.form>
    </.modal>
    """
  end

  defp submit_text(credential, form) do
    cond do
      form[:analyze].value in ["true", true] -> "Analyze query"
      credential.reviews_required > 0 -> "Request review"
      true -> "Run query"
    end
  end
end
