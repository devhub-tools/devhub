import { html, css, LitElement } from "lit"
import { customElement, property } from "lit/decorators.js"
import "@lit-labs/virtualizer"
import { brotliDecode } from "../../vendor/brotli"

type EditingFieldIndex = { columnIndex: number, rowIndex: number } | null;
type Cell = [string, string, boolean]
type Row = Cell[]
type Changes = Record<string, Record<string, string>>
type QueryResult = { columns: string[] | null, rows: Row[] | null, command: string | null, num_rows: number, messages: { message: string }[] }

@customElement("data-table")
export default class DataTable extends LitElement {
  @property({ type: Object })
  data: QueryResult | { error: string } | null = null

  @property({ type: Boolean, reflect: true })
  editable: boolean = false

  @property({ type: Boolean, reflect: true })
  sortable: boolean = false

  @property({ type: Object, reflect: true })
  orderBy: { field: string, direction: string } = { field: "", direction: "" }

  @property({ type: Object, reflect: true })
  changes: Changes = {}

  @property({ type: Boolean, reflect: true })
  filterable: boolean = false

  @property()
  primaryKeyName: string

  @property({ type: Object, attribute: false })
  editingFieldIndex: EditingFieldIndex = null

  editingElement: HTMLElement | null = null

  columnWidths: number[] = []
  primaryKeyIndex: number | null = null

  queryStartTime: number | null = null

  async connectedCallback() {
    super.connectedCallback()

    this._onUpdate()

    this.addEventListener("click", this._maybeSubmitEditForm)
    this.addEventListener("queryResult", (event: CustomEvent) => {
      this.data = event.detail
      this._onUpdate()
    })
    this.addEventListener("startStream", this._reset)
    this.addEventListener("streamResult", this._handleStreamData)
    this.addEventListener("streamDone", this._streamDone)
    this.addEventListener("export", this._export)
  }

  protected render() {
    if (this.data == null) return

    if (this.data.results) {
      return html`
        <div>
          ${this.data.results.map(result => html`
            <div style="margin: 1rem;">
              <span style="text-transform: uppercase;">${result}</span>
            </div>
          `)}
        </div>
      `
    }

    if (this.data.error) {
      return html`
        <div style="margin: 1rem;">
          <span style="text-transform: uppercase;">${this.data.error}</span>
        </div>
      `
    }

    if (this.data.command && this.data.columns === null) {
      return html`
        <div style="margin: 1rem;">
          <span style="text-transform: uppercase;">${this.data.command.replaceAll("_", " ")}</span>
          ${this.data.num_rows > 0 ? html`${this.data.num_rows}` : null}
        </div>
        ${this.data.messages && this.data.messages.length > 0 && this.data.messages.map(message => html`
          <div style="margin: 1rem;">
            <span>${message.message}</span>
          </div>
        `) || null}
      `
    }

    if (this.data.columns == null) return

    return html`
      <div id="data-table-container" style="width: fit-content; min-width: 100%; ${this.columnWidths.length === 0 ? "opacity: 0;" : ""}">
        <pre id="tooltip-container"></pre>
        ${this.data.columns.length > 0 ? html`<div class="header">
          ${this.data.columns.map(this.renderHeaderColumn)}
        </div>` : null}
        ${this.data.rows && this.data.rows.length > 0
        ? html`<lit-virtualizer .items=${this.data.rows} .renderItem=${(row, index) => this.renderRow(row, index, this.editingFieldIndex, this.changes)} @visibilityChanged=${this._onUpdate}></lit-virtualizer>`
        : html`<div style="padding: 1rem;">No records returned</div>`
      }
      </div>
    `
  }

  _reset = () => {
    this.data = null
    this.columnWidths = []
  }

  _maybeSubmitEditForm = (e: MouseEvent) => {
    if (this.editingElement) {
      const clickX = e.clientX
      const clickY = e.clientY
      const rect = this.editingElement.getBoundingClientRect()

      // Check if click coordinates are outside the editing element
      if (clickX < rect.left || clickX > rect.right || clickY < rect.top || clickY > rect.bottom) {
        this._submitEditForm(this.editingElement.form)
      }
    }
  }

  _handleStreamData = async (event: CustomEvent) => {
    const { chunk } = event.detail

    const uncompressed = brotliDecode(Int8Array.from(atob(chunk), c => c.charCodeAt(0)))
    const string = new TextDecoder().decode(uncompressed)
    const parsedValue = JSON.parse(string)

    if (!this.data) {
      this.data = parsedValue
      this.primaryKeyIndex = this.data?.columns ? this.data.columns.findIndex(col => col === this.primaryKeyName) : null
    } else {
      this.data.rows = this.data.rows!.concat(parsedValue.rows)
    }

    this._onUpdate()

    await new Promise((r) => setTimeout(r, 0))
  }

  _streamDone = () => {
    const numberOfRows = this.data?.rows?.length || 0
    this._onUpdate()

    this.pushEvent("query_finished", { numberOfRows })
  }

  _export = () => {
    if (!this.data || !this.data.columns || !this.data.rows) return

    const header = this.data.columns.map(col => `"${col}"`).join(",") + "\r\n"

    const rows = this.data.rows.map(row =>
      row
        .map((cell: Cell) => {
          if (cell[1] === "json" || cell[1] === "list") {
            return JSON.stringify(cell[0])
          }
          return cell[0]
        })
        .map(String)
        .map(v => v.replaceAll("\"", "\"\""))
        .map(v => `"${v}"`)
        .join(",")
    ).join("\r\n")

    const link = document.createElement("a")

    link.download = "query-result.csv"
    link.href = URL.createObjectURL(
      new Blob([header + rows], { type: "text/csv;charset=utf-8;" })
    )

    link.click()
  }

  _onUpdate = () => {
    if (!this.data || !this.data.columns) return

    requestAnimationFrame(async () => {
      await new Promise((r) => setTimeout(r, 0))
      this._watchTooltips()
      this._calculateColumnWidths()
    })
  }

  _watchTooltips() {
    const tooltipContainer = this.renderRoot?.querySelector("#tooltip-container")

    if (!tooltipContainer) return

    this.renderRoot?.querySelectorAll(".tooltip").forEach(tooltip => {
      tooltip.addEventListener("mouseenter", e => {
        if (!e.currentTarget) return
        const rect = e.currentTarget.getBoundingClientRect()
        tooltipContainer.innerHTML = e.target.getAttribute("data-tooltip")
        tooltipContainer.style.display = "block"
        // If the tooltip would extend beyond the right edge of the viewport
        if (e.screenX > -512) {
          tooltipContainer.style.left = ""
          tooltipContainer.style.right = `${window.innerWidth - rect.right}px`
        } else {
          tooltipContainer.style.right = ""
          tooltipContainer.style.left = `${rect.left}px`
        }

        if (e.screenY < window.innerHeight - 100) {
          tooltipContainer.style.top = `${rect.bottom}px`
        } else {
          const height = 68 + rect.bottom - rect.top
          tooltipContainer.style.top = `${rect.bottom - height}px`
        }
      })

      tooltip.addEventListener("mouseleave", e => {
        tooltipContainer.style.display = "none"
      })
    })
  }

  waitForElement = (selector: string, done: (el: HTMLElement) => void) => {
    const el = this.renderRoot?.querySelector(selector)
    if (el) done(el)
    else requestAnimationFrame(() => this.waitForElement(selector, done))
  }

  _calculateColumnWidths = () => {
    const numColumns = this.data.columns.length

    const container = this.renderRoot?.querySelector("#data-table-container")
    const maxWidth = Math.max(20, container?.clientWidth / 16 / (numColumns * .75))

    for (let i = 0; i < numColumns; i++) {
      const cells = this.renderRoot?.querySelectorAll(`.column-${i}`)

      let largestWidth = this.columnWidths[i] || 0

      cells.forEach(cell => {
        const width = cell.children[0].children[0].scrollWidth / 16
        if (width > largestWidth) largestWidth = width
      })

      this.columnWidths[i] = Math.min(largestWidth, maxWidth)

      cells.forEach(cell => {
        cell.style.width = (this.columnWidths[i] + 3).toFixed(2) + "rem"
      })
    }

    this.requestUpdate()
  }

  _sort(field: string) {
    if (this.sortable) {
      this.pushEvent("sort", { field })
    }
  }

  _addColumnFilter(field: string) {
    if (this.filterable) {
      this.pushEvent("add_column_filter", { field })
    }
  }

  _copyField(e: PointerEvent, value: string) {
    navigator.clipboard.writeText(value)

    if (!e.currentTarget) return

    const copyIcon = e.currentTarget.querySelector(".copy-icon")
    const copyCheck = e.currentTarget.querySelector(".copy-check")

    copyIcon.style.display = "none"
    copyCheck.style.display = "block"

    setTimeout(() => {
      copyCheck.style.display = "none"
      copyIcon.style.display = "block"
    }, 2000)
  }

  _edit(columnIndex: number, rowIndex: number) {
    this.editingFieldIndex = { columnIndex, rowIndex }
    this.waitForElement("#edit-input", (el) => {
      this.editingElement = el
      el.select()

      el.addEventListener("keydown", (e: KeyboardEvent) => {
        if (e.key === "Escape") {
          this.editingElement = null
          this.editingFieldIndex = null
        }

        if (e.key === "Enter") {
          e.preventDefault()
          this._submitEditForm(el.form)
        }
      })
    })
  }

  _submitEditForm(form) {
    const formData = new FormData(form)

    // Get the input value and field name to check if it actually changed
    const columnName = this.data.columns[this.editingFieldIndex?.columnIndex]
    const newValue = formData.get(columnName)
    const originalValue = this.data.rows[this.editingFieldIndex.rowIndex][this.editingFieldIndex.columnIndex][0]

    const event = newValue !== originalValue ? "stage_changes" : "unstage_changes"

    this.pushEvent(event, Object.fromEntries(formData))

    this.editingElement = null
    this.editingFieldIndex = null
  }

  renderHeaderColumn = (column: string, index: number) => {
    return html`
      <div class="column-header column-${index}" style="position: relative;">
        <div style="display: flex; align-items: center; justify-content: space-between; width: 100%; max-width: fit-content;">
          <div @click="${() => this._sort(column)}" style="display: flex; align-items: center; gap: 0.5rem; width: 100%; padding: 1rem; cursor: pointer;">
            ${column}
            ${this.orderBy?.field === column && this.orderBy?.direction === "desc" && html`
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="var(--gray-400)" class="size-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
              </svg>
            ` || null}
            ${this.orderBy?.field === column && this.orderBy?.direction === "asc" && html`
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="var(--gray-400)" class="size-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 15.75 7.5-7.5 7.5 7.5" />
              </svg>
            ` || null}
          </div>
          ${this.filterable && html`
            <div @click="${() => this._addColumnFilter(column)}" style="padding: 1rem; position: absolute; right: 0;">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="header-icon">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917 1.096v1.044a2.25 2.25 0 0 1-.659 1.591l-5.432 5.432a2.25 2.25 0 0 0-.659 1.591v2.927a2.25 2.25 0 0 1-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 0 0-.659-1.591L3.659 7.409A2.25 2.25 0 0 1 3 5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0 1 12 3Z" />
              </svg>
            </div>
          ` || null}
        </div>
      </div>
    `
  }

  // editingFieldIndex is passed to trigger a re-render
  renderRow = (row: Row, rowIndex: number, _editingFieldIndex: EditingFieldIndex, changes: Changes) => {
    let primaryKeyValue = null
    let rowChanges = null

    if (this.primaryKeyIndex !== null && this.primaryKeyIndex > -1) {
      primaryKeyValue = row[this.primaryKeyIndex][0]
      rowChanges = changes[primaryKeyValue]
    }

    return html`
      <div class="row">
        ${row.map((cell: Cell, columnIndex: number) => html`
          <div class=${"column-" + columnIndex} style="position: relative;">
            ${this.renderField(cell, primaryKeyValue, columnIndex, rowIndex, rowChanges)}
          </div>
        `)}
      </div>
    `
  }

  renderField = ([value, type, editable]: Cell, primaryKeyValue: string | null, columnIndex: number, rowIndex: number, rowChanges: Record<string, string> | null) => {
    editable = this.editable && editable
    const isEditing = this.editingFieldIndex?.columnIndex === columnIndex && this.editingFieldIndex?.rowIndex === rowIndex && primaryKeyValue
    const columnName = this.data.columns![columnIndex]
    const pendingChange = rowChanges && rowChanges[columnName]
    let content = html`<p>${pendingChange || value}</p>`

    switch (type) {
      case "date":
        content = html`<format-date date=${value} format="date"></format-date>`
        break

      case "datetime":
        content = html`<format-date date=${value} format="relative-datetime"></format-date>`
        break

      case "json":
      case "list":
        try {
          const json = JSON.stringify(value, null, 2)
          content = html`<p>${json.substring(0, 100)}</p>`
          value = json
        } catch (_e) {
          // ignore if not json
        }
        break
    }

    return html`
      <div class="field ${pendingChange ? "pending-change" : ""}">
        ${isEditing && this.renderEditForm(pendingChange || value, type, primaryKeyValue, columnName) || html`
        <div class="field-content">${content}</div>
        <div class="field-actions">
          <div style="display: flex; align-items: center; column-gap: 0.25rem; height: 100%;">
            <div class="tooltip" style="height: 1rem; width: 1rem;" data-tooltip=${value}>
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
              </svg>
            </div>
            <div class="copy-icon-container" @click="${(e: PointerEvent) => this._copyField(e, value)}">
              <svg class="copy-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 8.25V6a2.25 2.25 0 0 0-2.25-2.25H6A2.25 2.25 0 0 0 3.75 6v8.25A2.25 2.25 0 0 0 6 16.5h2.25m8.25-8.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-7.5A2.25 2.25 0 0 1 8.25 18v-1.5m8.25-8.25h-6a2.25 2.25 0 0 0-2.25 2.25v6" />
              </svg>
              <svg class="copy-check" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="rgb(var(--blue-600))">
                <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
              </svg>
            </div>
            ${editable && html`
            <div style="height: 1rem; width: 1rem; cursor: pointer;" @click="${() => this._edit(columnIndex, rowIndex)}">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10" />
              </svg>
            </div>
            ` || null}
          </div>
        </div>
        ` || null}
      </div>
    `
  }

  renderEditForm = (value: string, _type: string, primaryKeyValue: string, columnName: string) => {
    return html`
      <form>
        <input id="edit-input" type="text" name=${columnName} value=${value} />
        <input type="hidden" name="primary_key_value" value=${primaryKeyValue} />
      </form>
    `
  }

  static styles = css`
    :host {
      font-size: 0.75rem;
      line-height: 1rem;
      font-family: "Inter", sans-serif;
    }

    .header {
      height: 3rem;
      width: 100%;
      background-color: var(--surface-1);
      border-bottom: 1px solid var(--alpha-8);
      display: flex;
      position: sticky;
      top: 0;
      z-index: 10;
      text-align: left;
    }

    .header-icon {
      color: var(--gray-400);
    }

    svg {
      width: 1rem;
      height: 1rem;
    }

    .column-header {
      flex: none;
      display: flex;
      align-items: center;
    }

    .row {
      min-width: 100%;
      display: flex;
      border-bottom: 1px solid var(--alpha-8);
    }

    .row > div:not(:first-child), .column-header:not(:first-child) {
      border-style: solid;
      border-color: var(--alpha-4);
      border-width: 0px 0px 0px 1px;
    }

    .row:hover {
      background-color: var(--surface-2);
    }

    .field {
      height: 3rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
      column-gap: 0.5rem;
      padding: 0 1rem;
    }

    .field-content {
      width: 100%;
      max-width: fit-content;
    }

    .field-content > * {
      width: 100%;
      text-overflow: ellipsis;
      overflow: hidden;
      white-space: nowrap;
    }

    div .field-actions {
      display: none;
      position: absolute;
      right: 0;
      padding: 0.5rem;
      background-color: var(--surface-2);
    }

    div.pending-change .field-actions {
      background-color: rgb(var(--blue-200));
    }

    div:hover > .field-actions {
      display: block;
    }

    .copy-icon-container {
      height: 1rem;
      width: 1rem;
      cursor: pointer;
    }

    .copy-check {
      display: none;
    }

    #tooltip-container {
      position: fixed;
      display: none;
      background-color: var(--surface-4);
      padding: 1rem;
      border-radius: 0.25rem;
      z-index: 50;
      max-width: 32rem;
      text-wrap: wrap;
      word-break: break-all;
    }

    form {
      width: 100%;
      height: 100%;
    }

    #edit-input {
      width: 100%;
      height: 100%;
      font-size: 0.875rem;
      line-height: 1.25rem;
      border: none;
      outline: none;
      padding: 0 1rem;
      margin-left: -1rem;
      background-color: var(--gray-300);
      color: var(--gray-800);
    }

    .pending-change {
      background-color: rgb(var(--blue-200));
    }
  `
}