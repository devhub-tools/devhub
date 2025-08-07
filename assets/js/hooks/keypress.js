// Handles keyboard events for checkbox inputs, when the input is hidden by an icon.
export const SpaceToggleHook = {
  mounted() {
    // `querySelector` requires placing the hook on the parent element of the checkbox input.
    this.checkbox = this.el.querySelector("input[type=\"checkbox\"]")

    this.el.addEventListener("keydown", e => {
      this.handleKeydown(e)
    })
  },

  handleKeydown(e) {
    switch (e.code) {
      case "Space":
        this.checkbox.click()
        e.preventDefault()
        break

      default:
        return // noop
    }
  },
}

export const TextAreaSubmitHook = {
  mounted() {
    // sometimes the input is not clearing, so we clear it after the form is submitted
    this.el.form.addEventListener("submit", () => {
      setTimeout(() => this.el.value = "", 100)
    })

    this.el.addEventListener("keydown", e => {
      if (e.key == "Enter" && e.shiftKey == false) {
        e.preventDefault()
        this.el.form.dispatchEvent(
          new Event("submit", { bubbles: true, cancelable: true })
        )
      }
    })
  }
}

export const PreventSubmitHook = {
  mounted() {
    this.el.addEventListener("keydown", e => {
      if (e.key == "Enter") e.preventDefault()
    })
  }
}
