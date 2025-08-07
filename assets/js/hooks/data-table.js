export const DataTableHook = {
  mounted() {
    this.el.pushEvent = (event, detail) => this.pushEvent(event, detail)

    this.handleEvent(this.el.id + ":custom_event", ({ type, data }) => {
      const event = new CustomEvent(type, { detail: data })
      this.el.dispatchEvent(event)
    })

    document.getElementById(`${this.el.id}-copy-query-result`)?.addEventListener("click", () => {
      const data = this.el.data

      if (!data || !data.columns || !data.rows) return

      const header = data.columns.map(col => `"${col}"`).join("\t") + "\r\n"

      const rows = data.rows.map(row =>
        row
          .map(cell => cell[0])
          .map(String)
          .map(v => v.replaceAll("\"", "\"\""))
          .map(v => `"${v}"`)
          .join("\t")
      ).join("\r\n")

      navigator.clipboard.writeText(header + rows).then(() => {
        const copyIcon = document.querySelector(`#${this.el.id}-copy-query-result span`)

        copyIcon.classList.remove("hero-square-2-stack")
        copyIcon.classList.add("hero-check")
        copyIcon.classList.add("text-blue-600")

        setTimeout(() => {
          copyIcon.classList.remove("hero-check")
          copyIcon.classList.remove("text-blue-600")
          copyIcon.classList.add("hero-square-2-stack")
        }, 2000)
      })
    })
  },
}
