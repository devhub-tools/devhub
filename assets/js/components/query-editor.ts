import { EditorView, basicSetup } from "codemirror"
import { keymap } from "@codemirror/view"
import { EditorState, Compartment, Prec } from "@codemirror/state"
import { sql } from "@codemirror/lang-sql"
import { oneDark } from "../theme-one-dark"
import { oneLight } from "../theme-one-light"
import { StateField } from "@codemirror/state"
import { isDark } from "../hooks/theme-toggle"
import { acceptCompletion } from "@codemirror/autocomplete"
import { indentWithTab } from "@codemirror/commands"
import localforage from "localforage"

export default class CodeEditor extends HTMLElement {
  readOnly = this.getAttribute("read-only") === "true"
  localStorageKey = null

  constructor() {
    super()
    // element created
  }

  connectedCallback() {
    const language = new Compartment()
    const readOnly = new Compartment()
    const editorTheme = new Compartment()

    const schemaStr = this.getAttribute("schema")
    let schema
    if (schemaStr) {
      schema = JSON.parse(schemaStr)
    } else {
      schema = {}
    }

    const sqlConfig = {
      schema: schema,
      upperCaseKeywords: true,
    }

    const baseTheme = EditorView.baseTheme({
      "&": {
        fontSize: "16px",
      },
    })

    const listenChangesExtension = StateField.define({
      // we won't use the actual StateField value, null or undefined is fine
      create: () => null,
      update: (_value, transaction) => {
        if (transaction.docChanged || transaction.newSelection) {
          // access new content via the Transaction
          const str = transaction.newDoc.toJSON().join("\n")
          if (str && this.localStorageKey) {
            localforage.setItem(this.localStorageKey, str)
          }
        }
        return null
      },
    })

    const pushQuery = (eventType: string, results?: object) => {
      let query

      if (editor.state.selection.main.from === editor.state.selection.main.to) {
        query = editor.state.doc.toString()
      } else {
        query = editor.state.sliceDoc(editor.state.selection.main.from, editor.state.selection.main.to)
      }

      this.dispatchEvent(new CustomEvent(eventType, {
        detail: { query: query, selection: editor.state.selection, data: results },
      }))
    }

    const customKeyBindings = Prec.highest(
      keymap.of([
        {
          key: "Tab",
          run: acceptCompletion,
        },
        indentWithTab,
        {
          key: "Ctrl-Enter",
          run: () => {
            pushQuery("run-query")
            return true
          },
        },
        {
          key: "Mod-Enter",
          run: () => {
            pushQuery("run-query")
            return true
          },
        },
        {
          key: "Shift-Ctrl-Enter",
          run: () => {
            pushQuery("run-query-with-options")
            return true
          },
        },
        {
          key: "Shift-Mod-Enter",
          run: () => {
            pushQuery("run-query-with-options")
            return true
          },
        },
        {
          key: "Ctrl-s",
          run: () => {
            pushQuery("save-query")
            return true
          },
        },
        {
          key: "Mod-s",
          run: () => {
            pushQuery("save-query")
            return true
          },
        },
      ])
    )

    const state = EditorState.create({
      extensions: [
        basicSetup,
        customKeyBindings,
        editorTheme.of(isDark() ? oneDark : oneLight),
        baseTheme,
        language.of(sql(sqlConfig)),
        listenChangesExtension,
        // TODO: figure out why this still allows typing at the end
        readOnly.of(EditorState.readOnly.of(this.readOnly)),
      ],
    })

    const editor = new EditorView({
      state: state,
      parent: this,
    })

    this.addEventListener("themeToggled", () => {
      editor.dispatch({
        effects: editorTheme.reconfigure(
          isDark() ? oneDark : oneLight
        )
      })
    })

    this.addEventListener("setQuery", event => {
      this.localStorageKey = null

      editor.dispatch({
        changes: {
          from: 0,
          to: editor.state.doc.length,
          insert: event.data.query,
        },
      })
    })

    this.addEventListener("insertQuery", event => {
      editor.dispatch({
        changes: {
          from: editor.state.doc.length,
          insert: event.data.query,
        },
      })
    })

    this.addEventListener("loadFromLocalStorage", async event => {
      this.localStorageKey = event.data.localStorageKey
      const cached = await localforage.getItem(this.localStorageKey)

      const content = cached || event.data.default

      editor.dispatch({
        changes: {
          from: 0,
          to: editor.state.doc.length,
          insert: content,
        }
      })
    })

    this.addEventListener("resetLocalStorage", _event => {
      if (this.localStorageKey) localforage.removeItem(this.localStorageKey)
    })

    this.addEventListener("triggerRunQuery", () => pushQuery("run-query"))
    this.addEventListener("triggerRunQueryWithOptions", () => pushQuery("run-query-with-options"))
    this.addEventListener("triggerSaveQuery", () => pushQuery("save-query"))
    this.addEventListener("triggerShareQuery", () => {
      const dataTable = document.querySelector("data-table")
      pushQuery("share-query", { results: dataTable?.data })
    })

    const innerEditor = this.querySelector<HTMLElement>(".cm-editor")
    if (innerEditor) {
      innerEditor.style.height = "100%"
    }
  }

  disconnectedCallback() {
    // browser calls this method when the element is removed from the document
    // (can be called many times if an element is repeatedly added/removed)
  }

  static get observedAttributes() {
    return [
      /* array of attribute names to monitor for changes */
    ]
  }

  attributeChangedCallback(_name, _oldValue, _newValue) {
    // called when one of attributes listed above is modified
  }

  adoptedCallback() {
    // called when the element is moved to a new document
    // (happens in document.adoptNode, very rarely used)
  }

  // there can be other element methods and properties
}

customElements.define("query-editor", CodeEditor)
