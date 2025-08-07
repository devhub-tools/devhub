import { format } from "sql-formatter"

export const EditorHook = {
  mounted() {
    this.el.addEventListener("run-query", event => this.pushEvent("run_query", event.detail))
    this.el.addEventListener("run-query-with-options", event => this.pushEvent("show_query_options", event.detail))
    this.el.addEventListener("save-query", event => this.pushEvent("save_query", event.detail))
    this.el.addEventListener("share-query", event => this.pushEvent("show_shared_query_modal", event.detail))

    this.handleEvent("trigger_run_query", () => this.el.dispatchEvent(new Event("triggerRunQuery")))
    this.handleEvent("trigger_run_query_with_options", () => this.el.dispatchEvent(new Event("triggerRunQueryWithOptions")))
    this.handleEvent("trigger_save_query", () => this.el.dispatchEvent(new Event("triggerSaveQuery")))
    this.handleEvent("trigger_share_query", () => this.el.dispatchEvent(new Event("triggerShareQuery")))

    this.handleEvent("set_query", data => {
      const event = new Event("setQuery")
      event.data = data
      this.el.dispatchEvent(event)
    })

    this.handleEvent("insert_query", data => {
      let query
      let language

      switch (data.adapter) {
        case "postgres":
          language = "postgresql"
          break
        case "mysql":
          language = "mysql"
          break
      }

      try {
        query = format(data.query, { language: language })
      } catch (_e) {
        query = data.query
      }

      const event = new Event("insertQuery")
      event.data = { ...data, query: query }
      this.el.dispatchEvent(event)
    })

    this.handleEvent("load_from_local_storage", data => {
      const event = new Event("loadFromLocalStorage")
      event.data = data
      this.el.dispatchEvent(event)
    })

    this.handleEvent("reset_local_storage", () => {
      const event = new Event("resetLocalStorage")
      this.el.dispatchEvent(event)
    })
  },
}
