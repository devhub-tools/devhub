defmodule DevhubWeb.Live.Coverbot.Coverage do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Coverbot
  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub

  def mount(%{"coverage_id" => coverage_id}, _session, socket) do
    {:ok, coverage} = Coverbot.get_coverage(id: coverage_id, organization_id: socket.assigns.organization.id)

    files =
      with "refs/pull/" <> rest <- coverage.ref,
           {:ok, integration} <- Integrations.get_by(organization_id: socket.assigns.organization.id, provider: :github),
           number = rest |> String.split("/") |> List.first(),
           {:ok, files} <- GitHub.pull_request_files(integration, coverage.repository, number) do
        files
      else
        _error ->
          []
      end

    socket
    |> assign(
      page_title: "Devhub",
      coverage: coverage,
      files: files,
      breadcrumbs: [
        %{
          title: "#{coverage.repository.owner}/#{coverage.repository.name}",
          path: ~p"/coverbot/#{coverage.repository.id}"
        },
        %{title: coverage.ref}
      ]
    )
    |> ok()
  end

  def handle_params(params, _url, socket) do
    filter = params["filter"] || "partial"

    filtered_files =
      socket.assigns.files
      |> Enum.map(&parse_file(&1, socket.assigns.coverage.files[&1["filename"]], filter))
      |> Enum.filter(& &1.display?)

    socket
    |> assign(
      filter: filter,
      filtered_files: filtered_files
    )
    |> noreply()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header
        title={@coverage.repository.owner <> "/" <> @coverage.repository.name}
        subtitle={@coverage.ref}
      >
        <:actions>
          <div class="bg-alpha-4 divide-alpha-16 border-alpha-16 flex divide-x rounded border text-sm">
            <.link
              patch={~p"/coverbot/coverage/#{@coverage.id}"}
              class={"#{@filter == "partial" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
            >
              Partial Coverage
            </.link>
            <.link
              patch={~p"/coverbot/coverage/#{@coverage.id}?filter=all"}
              class={"#{@filter == "all" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
            >
              All Files
            </.link>
          </div>
        </:actions>
      </.page_header>
      <div
        :if={Enum.empty?(@filtered_files)}
        class="border-alpha-16 rounded-lg border-2 border-dashed p-12 text-center"
      >
        <.logo class="size-12 mx-auto text-gray-600" />

        <h3 class="mt-4 text-base font-semibold text-gray-900">All changes covered!</h3>
      </div>
      <div class="flex flex-col gap-y-4 rounded-lg" phx-hook="Highlight" id="files">
        <.file :for={file <- @filtered_files} file={file} />
      </div>
    </div>
    """
  end

  defp file(assigns) do
    ~H"""
    <div>
      <div class="bg-surface-0 top-[7.25rem] sticky">
        <div class="bg-surface-1 rounded-t-lg p-4">
          {@file.filename}
        </div>
      </div>
      <div class="bg-surface-1 overflow-hidden rounded-b-lg">
        <div class="flex">
          <div>
            <pre
              :for={line <- @file.lines}
              class={["w-12 px-1 text-right", line_coverage_color(line.covered)]}
            >{line.number}</pre>
          </div>
          <div class="w-full overflow-auto">
            <pre><code class={"language-#{@file.extension}"}><%= for line <- @file.lines, do: line.code <> "\n" %></code></pre>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp line_coverage_color(true), do: "bg-green-400"
  defp line_coverage_color(false), do: "bg-red-400"
  defp line_coverage_color(nil), do: "bg-alpha-4"

  defp parse_file(file, coverage, filter) do
    coverage = Coverbot.parse_file_coverage(coverage)

    {_ending_line_number, lines} =
      (file["patch"] || "")
      |> String.split("\n")
      |> Enum.reject(&String.starts_with?(&1, "-"))
      |> Enum.reduce({0, []}, fn line, {line_number, lines} ->
        line = String.replace_leading(line, "+", " ")

        case Regex.named_captures(~r/^@@ -\d+,\d+ \+(?<line_number>\d+),\d+ @@/, line) do
          %{"line_number" => line_number} ->
            line_number = String.to_integer(line_number)

            if line_number == 1 do
              {line_number, lines}
            else
              {line_number, [%{number: "...", covered: nil, code: ""} | lines]}
            end

          nil ->
            covered? = Coverbot.line_covered?(coverage, line_number)

            {line_number + 1,
             [
               %{
                 number: line_number,
                 covered: covered?,
                 code: line
               }
               | lines
             ]}
        end
      end)

    display? = filter == "all" or Enum.any?(lines, &(&1.covered == false))

    %{
      filename: file["filename"],
      display?: display?,
      lines: Enum.reverse(lines),
      extension: file["filename"] |> Path.extname() |> String.replace_leading(".", "")
    }
  end
end
