import Split from "split-grid"

export const SplitGridHook = {
  mounted() {
    Split({
      columnGutters: [
        {
          track: 1,
          element: document.querySelector(".gutter-col-1"),
        },
      ],
      rowGutters: [
        {
          track: 1,
          element: document.querySelector(".gutter-row-1"),
        },
      ],
      minSize: 1,
      onDragEnd: direction => {
        const style = document.querySelector(`.grid-${direction}`).style[`grid-template-${direction}s`]
        window.localStorage.setItem(`.grid-${direction}-style`, style)
      },
    })

    // TODO: figure out why resizing is messed up by code mirror
    setSplitSizes()
  }
}

const setSplitSizes = () => {
  const columnStyle = window.localStorage.getItem(".grid-column-style")
  const column = document.querySelector(".grid-column")
  if (column && columnStyle) column.style["grid-template-columns"] = columnStyle

  const rowStyle = window.localStorage.getItem(".grid-row-style")
  const row = document.querySelector(".grid-row")
  if (row && rowStyle) row.style["grid-template-rows"] = rowStyle
}