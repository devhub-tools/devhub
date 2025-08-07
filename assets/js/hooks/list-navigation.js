export const ListNavigationHook = {
  mounted() {
    addEventListener("keydown", e => handleKeyDown(e, this.el))
  }
}

const handleKeyDown = (event, el) => {
  const currentTarget = event.currentTarget
  if (!currentTarget) return

  const items = Array.from(el.querySelectorAll(".list-nav-item"))

  if (event.key === "Home") {
    event.preventDefault()

    items[0]?.focus()
  } else if (event.key === "End") {
    event.preventDefault()

    items[items.length - 1]?.focus()
  } else if (event.key === "ArrowUp" || event.key === "ArrowDown") {
    event.preventDefault()

    const currentIndex = items.findIndex((item) => document.activeElement === item)
    const nextIndex = currentIndex + (event.key === "ArrowUp" ? -1 : 1)
    items[nextIndex]?.focus()
  }
}