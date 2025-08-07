defmodule DevhubWeb.Components.QueryForm do
  @moduledoc false
  use DevhubWeb, :html

  def query_form(assigns) do
    ~H"""
    <div class="bg-surface-0 relative h-full">
      <div class="absolute inset-0 bottom-9 m-4 overflow-y-hidden rounded-lg" id="query-form">
        <query-editor
          schema={@schema}
          id="editor"
          value={@form_params["query"]}
          phx-update="ignore"
          phx-hook="Editor"
          database-id={@database.id}
        >
        </query-editor>
      </div>

      <div class="bg-surface-0 absolute inset-x-4 bottom-0 flex h-10 items-center justify-between">
        <div class="flex items-center gap-x-2">
          <button id="query-result-table-copy-query-result">
            <.icon name="hero-square-2-stack" class="size-5" />
          </button>
          <span class="text-alpha-24 text-sm">|</span>
          <.button phx-click="export" variant="text" class="hover:text-blue-600">
            Export
          </.button>
          <span class="text-alpha-24 text-sm">|</span>
          <.button phx-click="trigger_share_query" variant="text" class="hover:text-blue-600">
            Share
          </.button>
        </div>

        <div class="flex items-center justify-end gap-x-2">
          <%= if @query_running? do %>
            <div class="w-5">
              <.spinner />
            </div>
            <.button variant="secondary" phx-click="cancel_query">
              Cancel
            </.button>
          <% else %>
            <div :if={not is_nil(@query_run_time)} class="text-nowrap text-xs">
              {@query_run_time}ms
              <span class="text-alpha-24 text-sm">|</span> {@number_of_results} rows
            </div>

            <.dropdown id="query-options">
              <:trigger>
                <.icon name="hero-cog-6-tooth" class="size-5 text-gray-600" />
              </:trigger>
              <.form
                :let={f}
                for={@query_options}
                phx-change="update_user_query_preferences"
                class="bg-surface-4 absolute bottom-10 -left-8 flex w-44 origin-bottom-left flex-col gap-y-4 rounded p-4"
              >
                <.input field={f[:timeout]} type="number" label="Timeout (seconds)" phx-debounce />
                <.input field={f[:limit]} type="number" label="Default limit" phx-debounce />
              </.form>
            </.dropdown>

            <.button :if={@mode in ["library"]} variant="secondary" phx-click="reset_local_storage">
              Reset
            </.button>
            <.button
              :if={@mode in ["query", "history", "ai"]}
              phx-click="trigger_save_query"
              variant="secondary"
            >
              Save query
              <span class="ml-1.5 flex-none text-xs font-semibold text-gray-400">
                <kbd class="font-sans">⌘</kbd><kbd class="font-sans">S</kbd>
              </span>
            </.button>
            <.button :if={@mode == "library"} phx-click="trigger_save_query" variant="secondary">
              Update query
              <span class="ml-1.5 flex-none text-xs font-semibold text-gray-400">
                <kbd class="font-sans">⌘</kbd><kbd class="font-sans">S</kbd>
              </span>
            </.button>
            <.button
              :if={@current_credential.reviews_required > 0}
              phx-click="trigger_run_query"
              variant="outline"
            >
              Request review
              <span class="ml-1.5 flex-none text-xs font-semibold text-blue-500">
                <kbd class="font-sans">⌘</kbd><kbd class="font-sans">↵</kbd>
              </span>
            </.button>
            <div
              :if={@current_credential.reviews_required == 0}
              class="inline-flex cursor-pointer items-center justify-center divide-x divide-blue-600 whitespace-nowrap rounded-md text-sm font-bold text-blue-600 ring-1 ring-inset ring-blue-600 transition-colors hover:ring-blue-700 disabled:pointer-events-none disabled:opacity-50"
            >
              <button class="h-8 px-2 hover:text-blue-700" phx-click="trigger_run_query">
                Run query
                <span class="ml-1.5 flex-none text-xs font-semibold text-blue-500">
                  <kbd class="font-sans">⌘</kbd><kbd class="font-sans">↵</kbd>
                </span>
              </button>
              <button
                class="h-8 w-full pr-1 pl-0.5 text-center hover:text-blue-700"
                aria-label="Run query with options"
                phx-click="trigger_run_query_with_options"
              >
                <.icon name="hero-chevron-down-mini" />
              </button>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
