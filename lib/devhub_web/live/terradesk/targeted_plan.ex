defmodule DevhubWeb.Live.TerraDesk.TargetedPlan do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.TerraDesk
  alias Phoenix.LiveView.AsyncResult

  def mount(%{"id" => id}, _session, socket) do
    {:ok, workspace} = TerraDesk.get_workspace(id: id, organization_id: socket.assigns.organization.id)

    socket
    |> assign(
      page_title: "Devhub",
      workspace: workspace,
      form: to_form(%{}),
      filter_form: to_form(%{"filter" => ""}),
      selected_resources: [],
      breadcrumbs: [
        %{title: "TerraDesk", path: ~p"/terradesk"},
        %{title: workspace.name, path: ~p"/terradesk/workspaces/#{workspace.id}"},
        %{title: "Targeted plan"}
      ]
    )
    |> assign_async([:resources, :filtered_resources], fn ->
      resources = workspace |> TerraDesk.list_terraform_resources() |> parse_resources()
      {:ok, %{resources: resources, filtered_resources: Enum.map(resources, &elem(&1, 0))}}
    end)
    |> ok()
  end

  def render(assigns) do
    num_resources_selected = length(assigns.selected_resources)
    assigns = assign(assigns, num_resources_selected: num_resources_selected)

    ~H"""
    <div>
      <.page_header
        title={@workspace.name}
        subtitle={
          @workspace.repository && "#{@workspace.repository.owner}/#{@workspace.repository.name}"
        }
      >
        <:actions>
          <div class="flex">
            <div class="ml-auto flex items-center gap-x-2">
              <div class="mr-1 text-gray-600">Selected: {@num_resources_selected}</div>

              <.button
                phx-click="refresh_resources"
                variant="secondary"
                class="flex items-center gap-x-1"
              >
                <.icon name="hero-arrow-path" class="h-4 w-4" /> Refresh
              </.button>
              <.button phx-click="run_plan" disabled={@num_resources_selected == 0}>
                Plan
              </.button>
            </div>
          </div>
        </:actions>
      </.page_header>

      <.async_result :let={state} assign={@resources}>
        <:loading>
          <div class="mt-12 h-12">
            <.spinner />
          </div>
        </:loading>
        <:failed :let={_failure}>there was an error loading the resource list</:failed>

        <.form :let={f} for={@filter_form} phx-change="filter_resources">
          <.input type="text" label="search" field={f[:filter]} />
        </.form>

        <.form :let={f} for={@form} phx-change="select_resources" class="bg-surface-1 mt-4 rounded-lg">
          <div class="divide-alpha-8 flex flex-col divide-y">
            <%= for {key, items} <- state do %>
              <div class={[
                "flex w-full items-center pl-4",
                key not in @filtered_resources.result && "hidden"
              ]}>
                <.input type="checkbox" field={f[key]} />
                <div
                  class="flex w-full cursor-pointer justify-between p-4"
                  phx-click={
                    toggle("#" <> String.replace(key, ".", "-") <> "-items")
                    |> JS.toggle_class("rotate-90",
                      to: "#" <> String.replace(key, ".", "-") <> "-icon"
                    )
                  }
                >
                  <div>{URI.decode(key)}</div>
                  <div
                    :if={String.starts_with?(key, "module.")}
                    class="bg-alpha-4 size-6 flex items-center justify-center rounded-md"
                  >
                    <.icon
                      id={String.replace(key, ".", "-") <> "-icon"}
                      name="hero-chevron-right-mini"
                    />
                  </div>
                </div>
              </div>
              <div
                :if={String.starts_with?(key, "module.")}
                id={String.replace(key, ".", "-") <> "-items"}
                class="divide-alpha-8 hidden divide-y"
              >
                <div :for={{item, _index} <- items} class="ml-12 flex items-center gap-x-4 p-4">
                  <.input :if={@form[key].value in ["false", nil]} type="checkbox" field={f[item]} />
                  {URI.decode(item)}
                </div>
              </div>
            <% end %>
          </div>
        </.form>
      </.async_result>
    </div>
    """
  end

  def handle_event("select_resources", params, socket) do
    selected_resources =
      params
      |> Enum.filter(fn {_k, v} -> v == "true" end)
      |> Enum.map(&(&1 |> elem(0) |> URI.decode()))

    socket |> assign(form: to_form(params), selected_resources: selected_resources) |> noreply()
  end

  def handle_event("filter_resources", params, socket) do
    filtered_results =
      socket.assigns.resources.result
      |> Enum.filter(fn {key, items} ->
        String.contains?(key, params["filter"]) or
          Enum.any?(items, fn {item_key, _index} -> String.contains?(item_key, params["filter"]) end)
      end)
      |> Enum.map(&elem(&1, 0))

    filtered_resources = %{socket.assigns.filtered_resources | result: filtered_results}

    socket |> assign(filtered_resources: filtered_resources) |> noreply()
  end

  def handle_event("run_plan", _params, socket) do
    workspace = socket.assigns.workspace

    {:ok, plan} =
      TerraDesk.create_plan(
        workspace,
        workspace.repository.default_branch,
        user: socket.assigns.user,
        targeted_resources: socket.assigns.selected_resources,
        run: true
      )

    {:noreply, push_navigate(socket, to: ~p"/terradesk/plans/#{plan.id}")}
  end

  def handle_event("refresh_resources", _params, socket) do
    workspace = socket.assigns.workspace

    socket
    |> assign(
      resources: AsyncResult.loading(),
      filtered_resources: AsyncResult.loading()
    )
    |> assign_async([:resources, :filtered_resources], fn ->
      resources = workspace |> TerraDesk.list_terraform_resources(refresh: true) |> parse_resources()
      {:ok, %{resources: resources, filtered_resources: Enum.map(resources, &elem(&1, 0))}}
    end)
    |> noreply()
  end

  defp parse_resources(resources) do
    resources
    |> Enum.reject(&String.starts_with?(&1, "data."))
    |> Enum.map(&URI.encode_www_form/1)
    |> Enum.with_index()
    |> Enum.group_by(fn {item, _index} ->
      case String.split(item, ".") do
        ["module", module | _rest] -> "module." <> module
        _list -> item
      end
    end)
    |> Enum.sort_by(fn {_key, [{_item, index} | _rest]} -> index end)
  end
end
