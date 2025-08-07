import "phoenix_html"
import topbar from "../vendor/topbar"
import { LiveSocket } from "phoenix_live_view"
import { Socket } from "phoenix"

import { ChartHook } from "./hooks/charts"
import { DataTableHook } from "./hooks/data-table"
import { EditorHook } from "./hooks/editor"
import { HighlightHook } from "./hooks/highlight"
import { PasskeyHook } from "./hooks/passkey"
import { PreventSubmitHook, SpaceToggleHook, TextAreaSubmitHook } from "./hooks/keypress"
import { SelectNavigationHook } from "./hooks/select-navigation"
import { ListNavigationHook } from "./hooks/list-navigation"
import { SortableHook } from "./hooks/sortable"
import { SplitGridHook } from "./hooks/split-grid"
import { SqlHighlightHook } from "./hooks/sql-highlight"
import { isDark, ThemeToggleHook, toggleTheme } from "./hooks/theme-toggle"
import { WindowResizeHook } from "./hooks/window-resize"

import "./components/copy-text"
import "./components/copy-button"
import "./components/data-table"
import "./components/format-date"
import _ from "./components/query-editor"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

export const scrollToBottom = () => {
  setTimeout(() => {
    requestAnimationFrame(() => {
      window.scrollTo({
        top: document.documentElement.scrollHeight - window.innerHeight,
        left: 0,
        behavior: "smooth",
      })
    })
  }, 3)
}

const Hooks = {
  Chart: ChartHook,
  DataTable: DataTableHook,
  Editor: EditorHook,
  Highlight: HighlightHook,
  ListNavigation: ListNavigationHook,
  Passkey: PasskeyHook,
  PreventSubmit: PreventSubmitHook,
  SelectNavigation: SelectNavigationHook,
  Sortable: SortableHook,
  SpaceToggle: SpaceToggleHook,
  SplitGrid: SplitGridHook,
  SqlHighlight: SqlHighlightHook,
  TextAreaSubmit: TextAreaSubmitHook,
  ThemeToggle: ThemeToggleHook,
  WindowResize: WindowResizeHook,
  AutoFocus: {
    mounted() {
      this.el.focus()
    },
  },
  ScrollToEnd: {
    mounted() {
      this.handleEvent("scroll_to_end", scrollToBottom)
    },
  },
  ScrollToItem: {
    mounted() {
      this.el.scrollIntoView({ block: "center" })
    },
  },
}

toggleTheme(isDark())

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  longPollFallbackMs: false,
  params: { _csrf_token: csrfToken },
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.classList.contains("keep-style")) {
        to.style.cssText = from.style.cssText
      }
    },
  },
})

window.addEventListener("keydown", (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key === "k") {
    event.preventDefault()
    const commandPalette = document.getElementById("command-palette")
    liveSocket.execJS(commandPalette, commandPalette.getAttribute("data-toggle"))
  }
})

window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
  // Enable server log streaming to client.
  // Disable with reloader.disableServerLogs()
  reloader.enableServerLogs()
  window.liveReloader = reloader
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
