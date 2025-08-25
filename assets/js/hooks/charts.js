import Chart, { Colors } from "chart.js/auto"

Chart.register(Colors)

export const ChartHook = {
  mounted() {
    this.handleEvent("create_chart", data => createChart(data))
    updateChartColors()
  },
}

const createChart = (
  { id, datasets, data, labels, unit, type, max, links = [], displayLegend = false, stacked = false },
) => {
  const canvas = document.getElementById(id)
  const borderColor = getComputedStyle(document.documentElement).getPropertyValue("--alpha-8")
  const gray900 = getComputedStyle(document.documentElement).getPropertyValue("--gray-900").trim()
  const color = `rgb(${gray900})`

  if (!canvas) return
  if (canvas.chart) canvas.chart.destroy()

  const chart = new Chart(canvas, {
    type: type || "bar",
    data: {
      labels: labels,
      datasets: datasets || [
        {
          data: data,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: {
          border: { color: borderColor },
          grid: { display: false, color: borderColor },
          stacked: stacked,
          ticks: { maxRotation: 0, color: color },
          title: { display: true, text: unit, font: { size: 10 }, color: color },
        },
        y: {
          border: { display: false, },
          grid: { color: borderColor },
          max: max,
          stacked: stacked,
          ticks: { color: color, maxTicksLimit: 4 },
        },
      },
      plugins: {
        tooltip: {
          enabled: false,
          mode: "index",
          position: "nearest",
          external: externalTooltipHandler,
        },
        legend: { display: displayLegend, position: "bottom", onClick: legendClickHandler },
      },
      onClick: (_event, elements) => {
        if (elements.length > 0) {
          const firstElement = elements[0]
          const dataIndex = firstElement.index
          const link = links[dataIndex]
          if (link) window.location.href = link + window.location.search
        }
      },
      onHover: (event, chartElement) => {
        event.native.target.style.cursor = chartElement[0] ? "pointer" : "default"
      },
    },
  })

  canvas.chart = chart
}

export const updateChartColors = () => {
  const borderColor = getComputedStyle(document.documentElement).getPropertyValue("--alpha-16")
  const color = getComputedStyle(document.documentElement).getPropertyValue("--gray-900")

  const canvases = document.getElementsByTagName("canvas")

  Array.from(canvases).forEach(canvas => {
    if (canvas.chart) {
      canvas.chart.config._config.options.scales.x.border.color = borderColor
      canvas.chart.config._config.options.scales.y.grid.color = borderColor
      canvas.chart.config._config.options.scales.x.ticks.color = color
      canvas.chart.config._config.options.scales.y.ticks.color = color

      canvas.chart.update()
    }
  })
}

const getOrCreateTooltip = (chart) => {
  let tooltipEl = document.getElementById("chartjs-tooltip")

  if (!tooltipEl) {
    tooltipEl = document.createElement("div")
    tooltipEl.id = "chartjs-tooltip"
    tooltipEl.className = "rounded bg-surface-4 text-gray-900 absolute pointer-events-none -translate-x-1/2 z-10"
    tooltipEl.style.transition = "all .1s ease"

    chart.canvas.parentNode.appendChild(tooltipEl)
  }

  return tooltipEl
}

const externalTooltipHandler = (context) => {
  // Tooltip Element
  const { chart, tooltip } = context
  const tooltipEl = getOrCreateTooltip(chart)

  // Hide if no tooltip
  if (tooltip.opacity === 0) {
    tooltipEl.style.opacity = 0
    return
  }

  // Remove old children
  while (tooltipEl.firstChild) {
    tooltipEl.firstChild.remove()
  }

  const container = document.createElement("div")
  container.className = "p-2"

  // Set Text
  if (tooltip.body) {
    const titleLines = tooltip.title || []
    const bodyLines = tooltip.body.map(b => b.lines)

    titleLines.forEach(title => {
      const header = document.createElement("h1")
      header.className = "text-base font-semibold text-center mb-2"

      const text = document.createTextNode(title)

      header.appendChild(text)
      container.appendChild(header)
    })

    const dataContainer = document.createElement("div")
    dataContainer.className = "grid gap-2"
    if (bodyLines.length > 7 && bodyLines.length <= 20) dataContainer.className = "grid grid-cols-2 gap-2"
    if (bodyLines.length > 20) dataContainer.className = "grid grid-cols-3 gap-2"

    bodyLines.forEach((body, i) => {
      const colors = tooltip.labelColors[i]

      const row = document.createElement("div")
      row.className = "flex items-center"

      const box = document.createElement("span")
      box.className = "size-3 inline-block mr-2"
      box.style.background = colors.backgroundColor
      box.style.borderColor = colors.borderColor
      box.style.borderWidth = "2px"

      row.appendChild(box)

      const details = document.createElement("div")
      details.className = "grid grid-cols-2 w-full"

      const [label, value] = body[0].split(": ")

      const labelSpan = document.createElement("span")
      labelSpan.className = "font-semibold"
      labelSpan.appendChild(document.createTextNode(label))
      details.appendChild(labelSpan)

      if (value) {
        const valueSpan = document.createElement("span")
        valueSpan.className = "text-right"
        valueSpan.appendChild(document.createTextNode(value))
        details.appendChild(valueSpan)
      }

      row.appendChild(details)
      dataContainer.appendChild(row)
    })

    container.appendChild(dataContainer)
    tooltipEl.appendChild(container)
  }

  const { offsetLeft: positionX, offsetTop: positionY } = chart.canvas

  // Display, position, and set styles for font
  tooltipEl.style.opacity = 1
  tooltipEl.style.left = positionX + tooltip.caretX + "px"
  tooltipEl.style.top = positionY + tooltip.caretY + "px"
  tooltipEl.style.font = tooltip.options.bodyFont.string
  tooltipEl.style.padding = tooltip.options.padding + "px " + tooltip.options.padding + "px"
}

const legendClickHandler = (e, legendItem, legend) => {
  const index = legendItem.datasetIndex
  const ci = legend.chart

  const selfVisible = ci.isDatasetVisible(index)
  const anyItemsHidden = legend.legendItems.find(item => !ci.isDatasetVisible(item.datasetIndex))

  // this means user has selected a specific one and re-clicking to clear filter
  if (selfVisible && anyItemsHidden) {
    legend.legendItems.forEach((item) => {
      if (!ci.isDatasetVisible(item.datasetIndex)) ci.show(item.datasetIndex)
      item.hidden = false
    })

    return
  }

  legend.legendItems.forEach((item) => {
    if (item.datasetIndex !== index) {
      if (ci.isDatasetVisible(item.datasetIndex)) ci.hide(item.datasetIndex)
      item.hidden = true
    } else {
      if (!ci.isDatasetVisible(item.datasetIndex)) ci.show(item.datasetIndex)
      item.hidden = false
    }
  })
}
