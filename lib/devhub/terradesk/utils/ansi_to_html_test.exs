defmodule AnsiToHTMLTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Devhub.TerraDesk.Utils.AnsiToHTML

  doctest AnsiToHTML

  @pretty_inspect inspect(:hello, pretty: true, syntax_colors: [atom: :green])

  @custom_theme %Devhub.TerraDesk.Utils.AnsiTheme{
    container: {:code, [class: "container"]},
    "\e[32m": {:pre, [class: "green"]}
  }

  test "generate html string" do
    assert AnsiToHTML.generate_html(@pretty_inspect) ==
             ~s(<pre><span style="color: green;">:hello</span></pre>)
  end

  test "generate html string with theme" do
    assert AnsiToHTML.generate_html(@pretty_inspect, @custom_theme) ==
             ~s(<code class="container"><pre class="green">:hello</pre></code>)
  end

  test "generate phoenix html tag" do
    assert AnsiToHTML.generate_phoenix_html(@pretty_inspect) ==
             {:safe,
              [
                60,
                "pre",
                [],
                62,
                [
                  [
                    60,
                    "span",
                    [32, "style", 61, 34, "color: green;", 34],
                    62,
                    [":hello"],
                    60,
                    47,
                    "span",
                    62
                  ]
                ],
                60,
                47,
                "pre",
                62
              ]}
  end

  test "generate phoenix html with theme" do
    assert AnsiToHTML.generate_phoenix_html(@pretty_inspect, @custom_theme) ==
             {:safe,
              [
                60,
                "code",
                [" class=\"", "container", 34],
                62,
                [[60, "pre", [" class=\"", "green", 34], 62, [":hello"], 60, 47, "pre", 62]],
                60,
                47,
                "code",
                62
              ]}
  end

  test "supports e[38;5;nm 8 bit coloring" do
    color_line = IO.ANSI.color(228) <> "Howdy Partner"

    assert AnsiToHTML.generate_html(color_line) ==
             ~s{<pre><span style="color: rgb(255, 255, 102);">Howdy Partner</span></pre>}
  end

  test "supports e[38;2;r;g;bm 24 bit coloring" do
    color_line = IO.ANSI.color(5, 5, 2) <> "Howdy Partner"

    assert AnsiToHTML.generate_html(color_line) ==
             ~s{<pre><span style="color: rgb(255, 255, 102);">Howdy Partner</span></pre>}
  end

  test "supports e[48;5;nm 8 bit background coloring" do
    color_line = IO.ANSI.color_background(228) <> "Howdy Partner"

    assert AnsiToHTML.generate_html(color_line) ==
             ~s{<pre><span style="background-color: rgb(255, 255, 102);">Howdy Partner</span></pre>}
  end

  test "supports e[48;2;r;g;bm 24 bit background coloring" do
    color_line = IO.ANSI.color_background(5, 5, 2) <> "Howdy Partner"

    assert AnsiToHTML.generate_html(color_line) ==
             ~s{<pre><span style="background-color: rgb(255, 255, 102);">Howdy Partner</span></pre>}
  end

  test "defaults to no styling if ANSI code not recognized" do
    color_line = "\e[1234m Howdy Partner"

    log_output =
      capture_log(fn ->
        assert AnsiToHTML.generate_html(color_line) ==
                 "<pre><text> Howdy Partner</text></pre>"
      end)

    log_output =~ "[AnsiToHTML] ignoring unsupported ANSI style - \"\\e[1234m\"\n\e[0m"
  end
end
