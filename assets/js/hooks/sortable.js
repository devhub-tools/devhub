import Sortable from "sortablejs"

export const SortableHook = {
  mounted() {
    new Sortable(this.el, {
      animation: 150,
      draggable: ".sortable-item",
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      handle: ".sortable-handle",
      forceFallback: true,
      onEnd: () => {
        const input = this.el.querySelectorAll("input")[0]
        if (input) input.dispatchEvent(new Event("input", { bubbles: true }))
      },
    })
  },
}