import { highlight } from "sql-highlight"
import { format } from "sql-formatter"

export const SqlHighlightHook = {
  mounted() {
    formatQuery(this.el)
  },
  updated() {
    formatQuery(this.el)
  }
}

const formatQuery = (el) => {
  let query
  let language

  switch (el.dataset.adapter) {
    case "postgres":
      language = "postgresql"
      break
    case "mysql":
      language = "mysql"
      break
  }

  try {
    query = format(el.dataset.query, { language: language })
  } catch (_e) {
    query = el.dataset.query
  }

  el.innerHTML = highlight(query, { html: true })
}