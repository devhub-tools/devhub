defmodule Devhub.TerraDesk.Utils.AnsiToHTML do
  @moduledoc """
  AnsiToHTML is a small library to convert ANSI Styling codes to HTML using [phoenix_html](https://github.com/phoenixframework/phoenix_html).
  The library is not solely intended for use with `Phoenix` and can be easily used without it.
  """

  use PhoenixHTMLHelpers

  import Phoenix.HTML

  alias Devhub.TerraDesk.Utils.AnsiTheme

  @doc """
  Generates a new HTML string based on the passed ANSI string.

  Returns `String.t`.

  ## Examples

      iex> AnsiToHTML.generate_html(inspect :hello, pretty: true, syntax_colors: [atom: :green])
      "<pre><span style=\\"color: green;\\">:hello</span></pre>"

  """
  @spec generate_html(String.t(), AnsiTheme.t()) :: String.t()
  def generate_html(input, theme \\ %AnsiTheme{}) when is_map(theme),
    do: input |> generate_phoenix_html(theme) |> safe_to_string()

  @doc """
  Generates a new Phoenix HTML tag based on the passed ANSI string.

  Returns `Phoenix.HTML.Tag.t`.

  ## Examples

      iex> AnsiToHTML.generate_phoenix_html(inspect :hello, pretty: true, syntax_colors: [atom: :green])
      {:safe, [60, "pre", [], 62,
        [[60, "span", [32, "style", 61, 34, "color: green;", 34], 62, [":hello"],
          60, 47, "span", 62]], 60, 47, "pre", 62]}

  """
  @spec generate_phoenix_html(String.t(), AnsiTheme.t()) :: Phoenix.HTML.Tag.t()
  def generate_phoenix_html(input, theme \\ %AnsiTheme{}) when is_map(theme) do
    tokens =
      input
      # Remove cursor movement sequences
      |> String.replace(~r/\e\[(K|s|u|2J|2K|\d+(A|B|C|D|E|F|G|J|K|S|T)|\d+;\d+(H|f))/, "")
      # Remove carriage return
      |> String.replace(~r/#^.*\r(?!\n)#m/, "")
      |> tokenize()
      |> convert_to_tag(theme)

    case theme.container do
      :none ->
        tokens

      {container_tag, container_attr} ->
        content_tag(container_tag, tokens, container_attr)
    end
  end

  defp accumulate_ansi_chunks([], acc, chunks) do
    chunk_by_ansi_codes([], [acc | chunks])
  end

  defp accumulate_ansi_chunks(["\e[0m" | rem], acc, chunks) do
    chunk_by_ansi_codes(rem, [acc | chunks])
  end

  defp accumulate_ansi_chunks(["\e[" <> _rem = code | rem], acc, chunks) do
    accumulate_ansi_chunks(rem, [code], [acc | chunks])
  end

  defp accumulate_ansi_chunks([next | rem], acc, chunks) do
    accumulate_ansi_chunks(rem, [next | acc], chunks)
  end

  defp chunk_by_ansi_codes([], chunks), do: Enum.reverse(chunks)

  defp chunk_by_ansi_codes(["\e[0m" | rem], chunks) do
    chunk_by_ansi_codes(rem, chunks)
  end

  defp chunk_by_ansi_codes(["\e[7m" | rem], chunks) do
    # swap background and foreground code
    # if the next piece is a text color code, then this
    # attempts to make that the background and default
    # the text to black
    case rem do
      [<<"\e[3", color::binary-size(1), "m">> | next_rem] ->
        accumulate_ansi_chunks(next_rem, ["\e[4#{color}m", "\e[30m"], chunks)

      _rem ->
        chunk_by_ansi_codes(rem, chunks)
    end
  end

  defp chunk_by_ansi_codes(["\e[" <> _rem = code | rem], chunks) do
    accumulate_ansi_chunks(rem, [code], chunks)
  end

  defp chunk_by_ansi_codes([next | rem], []) do
    chunk_by_ansi_codes(rem, [[next]])
  end

  defp chunk_by_ansi_codes([next | rem], chunks) do
    chunk_by_ansi_codes(rem, [[next] | chunks])
  end

  defp convert_to_tag(tokens, theme) do
    Enum.map(tokens, fn token ->
      token
      |> Map.get(:styles, [])
      |> case do
        [] ->
          content_tag(:text, token.text)

        styles ->
          Enum.reduce(styles, nil, fn style, acc ->
            # credo:disable-for-next-line
            {token_tag, token_attr} = Map.get(theme, String.to_atom(style)) || default_style(style)

            content_tag(token_tag, acc || Map.get(token, :text), token_attr)
          end)
      end
    end)
  end

  defp tokenize(text) do
    text
    # Split by ANSI code
    |> String.split(~r/(?:\e\[(.*?)m|(\x08))/, include_captures: true, trim: true)
    |> chunk_by_ansi_codes([])
    # Group token data by type
    |> Enum.map(fn token -> Enum.group_by(token, &get_token_type/1) end)
  end

  defp get_token_type(token) do
    if String.starts_with?(token, "\e[") do
      :styles
    else
      :text
    end
  end

  # \e[38;5;228m - 8 bit color (Xterm)
  # \e[38;2;255;255;102m - 24 bit RGB
  defp default_style(<<"\e[38;", mode::binary-1, ";", color_m::binary>>) do
    {r, g, b} = parse_rgb(color_m, mode)
    {:span, [style: "color: rgb(#{r}, #{g}, #{b});"]}
  end

  # \e[48;5;228m - 8 bit color (Xterm)
  # \e[48;2;255;255;102m - 24 bit RGB
  defp default_style(<<"\e[48;", mode::binary-1, ";", color_m::binary>>) do
    {r, g, b} = parse_rgb(color_m, mode)
    {:span, [style: "background-color: rgb(#{r}, #{g}, #{b});"]}
  end

  defp default_style(style) do
    require Logger

    Logger.warning("[AnsiToHTML] ignoring unsupported ANSI style - #{inspect(style)}")
    {:text, []}
  end

  defp parse_rgb(rgb_m, "2") when is_bitstring(rgb_m) do
    # 255;255;203m
    ~r/[[:digit:]]+/
    |> Regex.scan(rgb_m)
    |> List.flatten()
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  defp parse_rgb(color_m, "5") when is_bitstring(color_m) do
    # 228m
    color_m
    |> Integer.parse()
    |> elem(0)
    |> parse_rgb("5")
  end

  defp parse_rgb(color, "5") when is_number(color) do
    color = color - 16
    blue = color |> rem(6) |> Kernel.*(51)
    green = color |> div(6) |> rem(6) |> Kernel.*(51)
    red = color |> div(36) |> rem(6) |> Kernel.*(51)
    {red, green, blue}
  end
end
