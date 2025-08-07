export const SelectNavigationHook = {
  mounted() {
    const actionName = this.el.getAttribute("phx-value-action")

    // Container items
    this.selectContainer = document.getElementById(actionName + "-options")
    this.options = this.selectContainer.children

    if (!this.el || !this.selectContainer || !this.options) {
      console.error("Select Navigation Hook: Missing required elements")
      return
    }

    this.resetIndex() // Initialize focus to the Search input

    // Add event listener to the text input
    this.el.addEventListener("keyup", e => {
      this.handleKeydown(e)
    })

    // Track focus state
    this.el.addEventListener("focus", e => {
      this.handleFocus(e)
    })

    // Select the contents of the checkbox when clicked -> allows users to
    // start typing immediately without having to highlight
    this.el.addEventListener("click", e => {
      this.el.select()
    })

    // Select search and open dropdown when clicking the icon
    this.selectIcon = document.getElementById(actionName + "-icon")
    this.selectIcon.addEventListener("click", _e => {
      this.el.focus()
    })

    // Add event listerner to the options container, to respond to arrow key presses
    this.selectContainer.addEventListener("keyup", e => {
      this.handleKeydown(e)
    })
  },


  // Open the dropdown when typing in the input, if not already opened
  ensureDropdownOpen(e) {
    const computedStyles = window.getComputedStyle(this.selectContainer)
    const displayStyle = computedStyles.display
    const isNavigationKey = e.key === "Tab" || e.key === "Shift"

    if (!isNavigationKey && displayStyle === "none") {
      this.resetIndex() // reset index when opening to keep state in sync
      this.el.click()
    }
  },

  // Handle key presses to navigate the dropdown
  handleKeydown(e) {
    this.trimSearchValue(e)
    this.ensureDropdownOpen(e)
    this.handleOpenKeypress(e)
    this.updateIndex(e)
    this.updateFocus(e)
  },

  // Trim the search value to remove leading whitespace, if opened with a "space"
  trimSearchValue(_e) {
    this.el.value = this.el.value.trimStart()
  },

  // "space" key opens the dropdown. We reset the filter to ensure that all options are available.
  handleOpenKeypress(e) {
    const isOpenKey = e.code === "Space"
    if (isOpenKey && this.isTabFocused) {
      this.isTabFocused = false // reset tab focus state
      this.pushEvent("clear_filter", {})
    }
  },

  // Track if the focus was caused by tabbing (i.e., not by mouse click)
  handleFocus(e) {
    this.isTabFocused = e.target === this.el && e.relatedTarget !== null
  },

  resetIndex(_e) {
    this.activeIndex = -1
  },

  // Track the focus index to handle list navigation with arrow keys
  updateIndex(e) {
    switch (e.key) {
      case "ArrowDown":
        this.activeIndex += 1
        break

      case "ArrowUp":
        this.activeIndex -= 1
        break

      default:
        e.preventDefault()
        e.stopPropagation()
        return // noop
    }
  },

  // Switches focus based on `activeIndex`
  updateFocus(_e) {
    // return to the search input
    if (this.activeIndex === -1 || this.activeIndex >= this.options.length) {
      this.resetIndex()
      this.el.focus()
    }
    // wrap around the last item to the search
    else if (this.activeIndex < -1) {
      this.el.blur()

      this.activeIndex = this.options.length - 1
      this.options[this.activeIndex]?.focus({ focusVisible: false })
    }
    // goto the next item on the list
    else {
      this.el.blur()

      this.options[this.activeIndex]?.focus({ focusVisible: false })
    }
  }
}
