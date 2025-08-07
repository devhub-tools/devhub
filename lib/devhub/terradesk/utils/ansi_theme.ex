defmodule Devhub.TerraDesk.Utils.AnsiTheme do
  @moduledoc """
  `AnsiToHTML.Theme` structs define how the ANSI should be converted to html tags.
  You can pass a custom theme to both `AnsiToHTML.generate_html/2` and `AnsiToHTML.generate_phoenix_html/2` as the second argument.

  Tags are matches against their ANSI code and converted to `Phoenix.HTML.Tag.t`.
  The expected pattern for a tag is a tuple of an atom representing the html tag, and a keyword list with it's html attributes.

  ## Examples

      iex> %AnsiToHTML.Theme{name: "My Theme", container: {:pre, [class: "container"]}, "\e[4m": {:span, [class: "has-underline"]}}
      %AnsiToHTML.Theme{"\e[1m": {:strong, []},
      "\e[30m": {:span, [style: "color: black;"]},
      "\e[31m": {:span, [style: "color: red;"]},
      "\e[32m": {:span, [style: "color: green;"]},
      "\e[33m": {:span, [style: "color: yellow;"]},
      "\e[34m": {:span, [style: "color: blue;"]},
      "\e[35m": {:span, [style: "color: magenta;"]},
      "\e[36m": {:span, [style: "color: cyan;"]},
      "\e[37m": {:span, [style: "color: white;"]}, "\e[3m": {:i, []},
      "\e[40m": {:span, [style: "background-color: black;"]},
      "\e[41m": {:span, [style: "background-color: red;"]},
      "\e[42m": {:span, [style: "background-color: green;"]},
      "\e[43m": {:span, [style: "background-color: yellow;"]},
      "\e[44m": {:span, [style: "background-color: blue;"]},
      "\e[45m": {:span, [style: "background-color: magenta;"]},
      "\e[46m": {:span, [style: "background-color: cyan;"]},
      "\e[47m": {:span, [style: "background-color: white;"]},
      "\e[49m": {:span, [style: "background-color: black;"]},
      "\e[4m": {:span, [class: "has-underline"]},
      "\e[9m": {:span, [style: "text-decoration: line-through;"]},
      container: {:pre, [class: "container"]}, name: "My Theme"}
  """
  defstruct(
    name: "Default Theme",
    container: {:pre, []},
    "\e[1m": {:strong, []},
    "\e[3m": {:i, []},
    "\e[4m": {:span, [style: "text-decoration: underline;"]},
    "\e[9m": {:span, [style: "text-decoration: line-through;"]},
    "\e[30m": {:span, [style: "color: black;"]},
    "\e[31m": {:span, [style: "color: red;"]},
    "\e[32m": {:span, [style: "color: green;"]},
    "\e[33m": {:span, [style: "color: yellow;"]},
    "\e[34m": {:span, [style: "color: blue;"]},
    "\e[35m": {:span, [style: "color: magenta;"]},
    "\e[36m": {:span, [style: "color: cyan;"]},
    "\e[37m": {:span, [style: "color: white;"]},
    "\e[90m": {:span, [style: "color: rgb(85,85,85);"]},
    # default to the text color in browser
    "\e[39m": {:text, []},
    "\e[40m": {:span, [style: "background-color: black;"]},
    "\e[41m": {:span, [style: "background-color: red;"]},
    "\e[42m": {:span, [style: "background-color: green;"]},
    "\e[43m": {:span, [style: "background-color: yellow;"]},
    "\e[44m": {:span, [style: "background-color: blue;"]},
    "\e[45m": {:span, [style: "background-color: magenta;"]},
    "\e[46m": {:span, [style: "background-color: cyan;"]},
    "\e[47m": {:span, [style: "background-color: white;"]},
    "\e[49m": {:span, [style: "background-color: black;"]}
  )

  def new(attrs) when is_list(attrs), do: new(Map.new(attrs))

  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> Map.from_struct()
    |> Map.merge(attrs)
  end
end
