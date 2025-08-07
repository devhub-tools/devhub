import hljs from "highlight.js/lib/common"
import elixir from "highlight.js/lib/languages/elixir"
import erlang from "highlight.js/lib/languages/erlang"

hljs.registerLanguage("elixir", elixir)
hljs.registerLanguage("erlang", erlang)

export const HighlightHook = {
  mounted() {
    hljs.highlightAll()
  },
  updated() {
    hljs.highlightAll()
  }
}
