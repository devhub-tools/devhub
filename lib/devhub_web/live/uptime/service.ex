defmodule DevhubWeb.Live.Uptime.Service do
  @moduledoc """
  Service page shows checks results for a specific service.
  """
  use DevhubWeb, :live_view

  alias Devhub.Uptime
  alias Devhub.Uptime.Schemas.Check
  alias Phoenix.LiveView.AsyncResult

  @show_checks_since DateTime.add(DateTime.utc_now(), -24, :hour)
  @show_checks_until DateTime.utc_now()
  @page_size (Application.compile_env(:devhub, :compile_env) == :test && 2) || 50

  def mount(%{"id" => id}, _session, socket) do
    initial_check_limit = 50

    {:ok, service} = Uptime.get_service(id: id, organization_id: socket.assigns.organization.id)

    # wait to fetch checks until window size is known
    service = Map.put(service, :checks, [])

    socket
    |> assign(
      page_title: "Devhub",
      badge_data: AsyncResult.loading(),
      chart_data: AsyncResult.loading(),
      loading: true,
      check_limit: initial_check_limit,
      filter_form: to_form(%{}),
      next_cursor: nil,
      prev_cursor: nil,
      service: service,
      show_checks_since: @show_checks_since,
      show_checks_until: @show_checks_until,
      start_date: DateTime.add(DateTime.utc_now(), -90, :day),
      end_date: DateTime.utc_now(),
      breadcrumbs: [%{title: "Uptime", path: ~p"/uptime"}, %{title: service.name}]
    )
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      start_date = start_date_from_params(params)
      end_date = end_date_from_params(socket.assigns.user.timezone, params)

      Uptime.subscribe_checks(socket.assigns.service.id)

      params =
        params
        |> Devhub.Utils.delete_if_empty("request_time")
        |> Devhub.Utils.delete_if_empty("status")

      start_time =
        start_date
        |> Timex.to_datetime(socket.assigns.user.timezone)
        |> Timex.Timezone.convert("UTC")

      end_time =
        end_date
        |> Timex.to_datetime(socket.assigns.user.timezone)
        |> Timex.end_of_day()
        |> Timex.Timezone.convert("UTC")

      filters =
        Enum.reject(
          [
            request_time: params["request_time"] && {:greater_than, params["request_time"]},
            status: (params["status"] != "all" && params["status"]) || nil,
            inserted_at: {:greater_than, start_time},
            inserted_at: {:less_than, end_time}
          ],
          &(&1 |> elem(1) |> is_nil())
        )

      socket
      |> assign(
        loading: false,
        start_date: start_date,
        end_date: end_date,
        filter_form:
          to_form(%{
            "status" => params["status"],
            "request_time" => params["request_time"],
            "start_date" => start_date,
            "end_date" => end_date
          }),
        filters: filters
      )
      |> paginate_checks(nil, true)
      |> fetch_chart_data()
      |> fetch_badge_data()
      |> noreply()
    else
      {:noreply, socket}
    end
  end

  def render(%{loading: true} = assigns) do
    ~H""
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title={@service.name} subtitle={@service.url}>
        <:actions>
          <.live_component
            id="test-now-button"
            module={DevhubWeb.Components.Uptime.TestNowButton}
            service={@service}
          />
          <.link_button
            :if={@permissions.super_admin}
            type="button"
            navigate={~p"/uptime/services/#{@service.id}/settings"}
          >
            Edit
          </.link_button>
        </:actions>
      </.page_header>
      <div class="flex flex-col gap-y-4">
        <div class="bg-surface-1 rounded-lg p-4">
          <div class="flex flex-row flex-wrap space-x-4">
            <.async_result :let={data} assign={@badge_data}>
              <div>
                <.link
                  target="_blank"
                  href={"https://img.shields.io/endpoint?url=#{URI.encode("#{DevhubWeb.Endpoint.url()}/api/v1/uptime/#{@service.id}/uptime/7d/badge.json")}"}
                >
                  <.shield_badge type={:uptime} duration="7d" uptime={data.uptime_percentage} />
                </.link>
              </div>
              <div>
                <.link
                  target="_blank"
                  href={"https://img.shields.io/endpoint?url=#{URI.encode("#{DevhubWeb.Endpoint.url()}/api/v1/uptime/#{@service.id}/latency/7d/badge.json")}"}
                >
                  <.shield_badge type={:latency} duration="7d" average_response_time={data.latency} />
                </.link>
              </div>
              <div :if={not Enum.empty?(@service.checks)}>
                <.link
                  target="_blank"
                  href={"https://img.shields.io/endpoint?url=#{URI.encode("#{DevhubWeb.Endpoint.url()}/api/v1/uptime/#{@service.id}/health/badge.json")}"}
                >
                  <.shield_badge type={:health} up={hd(@service.checks).status == :success} />
                </.link>
              </div>
            </.async_result>
          </div>
          <div id="window-resize" phx-hook="WindowResize" class="mt-4">
            <.service_checks_summary
              checks={@service.checks}
              window_started_at={@show_checks_since}
              window_ended_at={@show_checks_until}
              total={@check_limit}
            />
          </div>
        </div>

        <.async_result assign={@chart_data}>
          <:loading>
            <div class="flex h-72 items-center justify-center">
              <div class="size-10">
                <.spinner />
              </div>
            </div>
          </:loading>
          <div id="charts" phx-hook="Chart">
            <div class="bg-surface-1 flex h-80 rounded-lg p-4">
              <canvas id="service-history-chart" phx-update="ignore" />
            </div>
          </div>
        </.async_result>
        <div>
          <.form
            :let={f}
            for={@filter_form}
            phx-change="update_filters"
            class="mb-4 grid grid-cols-4 gap-x-2"
          >
            <.input
              type="select"
              field={f[:status]}
              label="Status"
              options={[
                {"All", "all"},
                {"Success", "success"},
                {"Failure", "failure"},
                {"Timeout", "timeout"}
              ]}
            />
            <.input
              field={f[:request_time]}
              type="text"
              placeholder="Filter request times"
              label="Request time"
              phx-debounce
            />
            <.input type="date" field={f[:start_date]} label="Start date" />
            <.input type="date" field={f[:end_date]} label="End date" />
          </.form>

          <div id="check-table-container" class="bg-surface-1 rounded-lg p-4">
            <.table
              id="check-table"
              rows={@streams.checks}
              row_click={&toggle_slide("##{elem(&1, 0)}-drawer-content")}
              phx_viewport_top={not is_nil(@prev_cursor) && "prev_page"}
              phx_viewport_bottom={!@end_of_timeline? && "next_page"}
              tbody_class={
                Enum.join(
                  [
                    if(@end_of_timeline?, do: "pb-10", else: "pb-[calc(200vh)]"),
                    if(is_nil(@prev_cursor), do: "pt-10", else: "pt-[calc(200vh)]")
                  ],
                  " "
                )
              }
            >
              <:col :let={{_dom_id, check}} label="Status"><.check_status check={check} /></:col>
              <:col :let={{_dom_id, check}} label="Date">
                <format-date date={check.inserted_at} />
              </:col>
              <:col :let={{_dom_id, check}} label="Status code">{check.status_code}</:col>
              <:col :let={{_dom_id, check}} label="Request time">{check.request_time}ms</:col>
              <:col class="w-1/12">
                <div class="flex items-center justify-end">
                  <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                    <.icon name="hero-chevron-right-mini" />
                  </div>
                </div>
              </:col>
            </.table>
          </div>
        </div>
      </div>

      <div id="check-drawer" phx-update="stream">
        <.drawer :for={{dom_id, check} <- @streams.checks} id={dom_id <> "-drawer"} width="w-[40rem]">
          <div class="space-y-2 text-sm">
            <div class="flex items-center justify-center">
              <span class="text-md text-muted-foreground">
                <format-date date={check.inserted_at} format="datetime"></format-date>
              </span>
            </div>
            <p>
              <span class="font-semibold">Status code</span>: {check.status_code}
            </p>
            <p :if={check.dns_time}>
              <span class="font-semibold">DNS time</span>: {check.dns_time}ms
            </p>

            <p :if={check.connect_time}>
              <span class="font-semibold">Connect time</span>: {check.connect_time}ms
            </p>

            <p :if={check.tls_time}>
              <span class="font-semibold">TLS time</span>: {check.tls_time}ms
            </p>

            <p :if={check.first_byte_time}>
              <span class="font-semibold">Time to first byte</span>: {check.first_byte_time}ms
            </p>

            <p :if={check.request_time}>
              <span class="font-semibold">Total time</span>: {check.request_time}ms
            </p>

            <div :if={check.response_body} class="pt-6">
              <span class="font-semibold">Response</span>:
              <div class="bg-surface-3 mt-4 overflow-auto rounded p-4 text-sm">
                <pre><%= check.response_body %></pre>
              </div>
            </div>
            <div :if={check.response_headers} class="pt-6">
              <span class="font-semibold">Response Headers</span>:
              <.table
                rows={Enum.sort_by(check.response_headers, & &1.key)}
                id={"#{check.id}-response-headers"}
              >
                <:col :let={header} label="Key" class="w-1/3">
                  {String.downcase(header.key)}
                </:col>
                <:col :let={header} label="Value">
                  <div class="overflow-x-auto">
                    {header.value}
                  </div>
                </:col>
              </.table>
            </div>
          </div>
        </.drawer>
      </div>
    </div>
    """
  end

  def handle_event("window_resize", values, socket) do
    check_limit = values |> Map.get("width", 800) |> calculate_checks_limit()

    {:ok, service} =
      Uptime.get_service(
        [id: socket.assigns.service.id],
        preload_checks: true,
        limit_checks: check_limit
      )

    socket
    |> assign(
      service: service,
      check_limit: check_limit
    )
    |> noreply()
  end

  def handle_event("update_filters", params, socket) do
    params = Map.take(params, ["status", "request_time", "start_date", "end_date"])

    params =
      (socket.assigns.uri.query || "")
      |> URI.decode_query()
      |> Map.merge(params)

    socket |> push_patch(to: ~p"/uptime/services/#{socket.assigns.service.id}?#{params}") |> noreply()
  end

  def handle_event("next_page", _params, socket) do
    {:noreply, paginate_checks(socket, {:next, socket.assigns.next_cursor})}
  end

  def handle_event("prev_page", %{"_overran" => true}, socket) do
    {:noreply, paginate_checks(socket, nil)}
  end

  def handle_event("prev_page", _params, socket) do
    if is_nil(socket.assigns.prev_cursor) do
      {:noreply, socket}
    else
      {:noreply, paginate_checks(socket, {:prev, socket.assigns.prev_cursor})}
    end
  end

  def handle_info({Check, %Check{} = check}, socket) do
    # Handle new checks, keep the list fixed to a calculated amount by removing the last element.
    %{service: %{checks: checks} = service, check_limit: check_limit} = socket.assigns
    checks = if length(checks) >= check_limit, do: List.delete_at(checks, -1), else: checks

    socket
    |> assign(service: %{service | checks: [check | checks]})
    |> maybe_stream_insert(check)
    |> noreply()
  end

  def handle_async(:badge_data, {:ok, data}, socket) do
    socket
    |> assign(badge_data: AsyncResult.ok(socket.assigns.badge_data, data))
    |> noreply()
  end

  def handle_async(:chart_data, {:ok, data}, socket) do
    socket
    |> assign(chart_data: AsyncResult.ok(socket.assigns.chart_data, data))
    |> push_event("create_chart", data)
    |> noreply()
  end

  def handle_async(:chart_data, {:exit, reason}, socket) do
    socket
    |> assign(chart_data: AsyncResult.failed(socket.assigns.chart_data, {:exit, reason}))
    |> put_flash(:error, "Failed to load chart")
    |> noreply()
  end

  defp maybe_stream_insert(socket, check) do
    filters = socket.assigns.filters

    end_time =
      socket.assigns.end_date
      |> Timex.to_datetime(socket.assigns.user.timezone)
      |> Timex.end_of_day()
      |> Timex.Timezone.convert("UTC")

    status = Keyword.get(filters, :status)
    request_time = Keyword.get(filters, :request_time)
    inserted_at = check.inserted_at
    not_date_filtered? = DateTime.before?(inserted_at, end_time)

    if is_nil(status) and is_nil(request_time) and not_date_filtered? do
      stream_insert(socket, :checks, check, at: 0, limit: @page_size)
    else
      socket
    end
  end

  defp fetch_chart_data(socket) do
    %{service: service, start_date: start_date, end_date: end_date} = socket.assigns

    start_async(socket, :chart_data, fn ->
      Uptime.service_history_chart(service, start_date, end_date)
    end)
  end

  defp fetch_badge_data(socket) do
    %{service: service} = socket.assigns

    start_async(socket, :badge_data, fn ->
      uptime_percentage = Uptime.uptime_percentage(service.id, "7d")
      latency = Uptime.latency(service.id, "7d")

      %{
        uptime_percentage: uptime_percentage,
        latency: latency
      }
    end)
  end

  defp paginate_checks(socket, cursor, reset \\ false) do
    %{prev_cursor: prev_cursor, next_cursor: next_cursor, filters: filters} = socket.assigns

    checks = Uptime.list_checks(socket.assigns.service, cursor: cursor, filters: filters, limit: @page_size)

    prev_cursor =
      cond do
        is_nil(cursor) -> nil
        Enum.empty?(checks) -> prev_cursor
        true -> List.first(checks).id
      end

    next_cursor = (not Enum.empty?(checks) && List.last(checks).id) || next_cursor

    {checks, at, limit} =
      case cursor do
        {:prev, _next_cursor} ->
          {Enum.reverse(checks), 0, @page_size * 3}

        _next_or_first ->
          {checks, -1, @page_size * 3 * -1}
      end

    case {checks, cursor} do
      {[], {:prev, _prev_cursor}} ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(prev_cursor: nil, next_cursor: next_cursor)

      {[], _cursor} ->
        socket
        |> assign(end_of_timeline?: at == -1)
        |> stream(:checks, checks, at: at, limit: limit, reset: reset)
        |> assign(prev_cursor: prev_cursor, next_cursor: next_cursor)

      {[_head | _tail] = checks, _cursor} ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(prev_cursor: prev_cursor, next_cursor: next_cursor)
        |> stream(:checks, checks, at: at, limit: limit, reset: reset)
    end
  end
end
