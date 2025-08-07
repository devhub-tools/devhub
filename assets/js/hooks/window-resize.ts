import { type Hook, debounce } from "../helpers"

type WindowResize = {
  resize?: (ev: Event) => void;
} & Hook;

export const WindowResizeHook: WindowResize = {
  mounted() {
    const update = debounce(() => {
      this.pushEvent?.("window_resize", {
        width: this.el.offsetWidth,
      })
    }, 250)

    // Send initial window size
    update()
    // Watch for changes in the window size
    this.resize = (_ev: Event) => {
      update()
    }
    window.addEventListener("resize", this.resize)
  },
  updated() {
    this.pushEvent?.("window_resize", {
      width: this.el.offsetWidth,
    })
  },
  destroyed() {
    if (this.resize) {
      window.removeEventListener("resize", this.resize)
    }
  },
}
