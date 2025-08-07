import { EditorView } from "@codemirror/view"
import { HighlightStyle, syntaxHighlighting } from "@codemirror/language"
import { tags } from "@lezer/highlight"

const settings = {
  background: "#f5f7fa",
  gutterBackground: "#f5f7fa",
  lineHighlight: "rgba(17, 24, 39, 0.04)",
  foreground: "#4D4D4C",
  caret: "#AEAFAD",
  selection: "#D6D6D6",
  gutterForeground: "#4D4D4C80",
}
const oneLightTheme = EditorView.theme({
  "&": {
    color: settings.foreground,
    backgroundColor: settings.background
  },
  ".cm-content": {
    caretColor: settings.caret,
  },
  ".cm-cursor, .cm-dropCursor": {
    borderLeftColor: settings.caret,
  },
  "&.cm-focused .cm-selectionBackgroundm .cm-selectionBackground, .cm-content ::selection":
  {
    backgroundColor: settings.selection,
  },
  ".cm-activeLine": {
    backgroundColor: settings.lineHighlight,
  },
  ".cm-gutters": {
    backgroundColor: settings.gutterBackground,
    color: settings.gutterForeground,
  },
  ".cm-activeLineGutter": {
    backgroundColor: settings.lineHighlight,
  },
}, { dark: false })
/**
The highlighting style for code in the One Dark theme.
*/
const oneLightHighlightStyle = HighlightStyle.define([
  {
    tag: tags.comment,
    color: "#8E908C",
  },
  {
    tag: [tags.variableName, tags.self, tags.propertyName, tags.attributeName, tags.regexp],
    color: "#C82829",
  },
  {
    tag: [tags.number, tags.bool, tags.null],
    color: "#F5871F",
  },
  {
    tag: [tags.className, tags.typeName, tags.definition(tags.typeName)],
    color: "#C99E00",
  },
  {
    tag: [tags.string, tags.special(tags.brace)],
    color: "#718C00",
  },
  {
    tag: tags.operator,
    color: "#3E999F",
  },
  {
    tag: [tags.definition(tags.propertyName), tags.function(tags.variableName)],
    color: "#4271AE",
  },
  {
    tag: tags.keyword,
    color: "#8959A8",
  },
  {
    tag: tags.derefOperator,
    color: "#4D4D4C",
  },
])
/**
Extension to enable the One Dark theme (both the editor theme and
the highlight style).
*/
const oneLight = [oneLightTheme, syntaxHighlighting(oneLightHighlightStyle)]

export { oneLight }
