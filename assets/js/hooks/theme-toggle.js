import { updateChartColors } from "./charts"

export const ThemeToggleHook = {
  mounted() {
    this.toggle = (_ev) => {
      toggleTheme(!isDark())
    }
    const button = document.getElementById("theme-toggle")
    if (button instanceof HTMLButtonElement) {
      button.addEventListener("click", this.toggle)
    }
    toggleTheme(isDark())
  },

  destroyed() {
    if (this.toggle && this.button) {
      this.button.removeEventListener("click", this.toggle)
    }
  },
}

export const isDark = () => {
  if (localStorage.theme === "dark") return true
  if (localStorage.theme === "light") return false
  return window.matchMedia("(prefers-color-scheme: dark)").matches
}

export const toggleTheme = (dark) => {
  const themeToggleDarkIcon = document.getElementById("theme-toggle-dark-icon")
  const themeToggleLightIcon = document.getElementById("theme-toggle-light-icon")

  const show = dark ? themeToggleDarkIcon : themeToggleLightIcon
  const hide = dark ? themeToggleLightIcon : themeToggleDarkIcon
  if (show) show.classList.remove("hidden", "text-transparent")
  if (hide) hide.classList.add("hidden", "text-transparent")

  if (dark) {
    document.documentElement.classList.add("dark")
  } else {
    document.documentElement.classList.remove("dark")
  }

  localStorage.theme = dark ? "dark" : "light"

  updateChartColors()

  const editor = document.getElementById("editor")

  if (editor) {
    const event = new CustomEvent("themeToggled", {
      bubbles: true,
      cancelable: false,
      composed: true
    })

    editor.dispatchEvent(event)
  }
}
