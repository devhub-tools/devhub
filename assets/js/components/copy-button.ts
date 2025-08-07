import { html, css, LitElement } from "lit"
import { customElement, property } from "lit/decorators.js"

@customElement("copy-button")
export default class CopyButton extends LitElement {
  @property()
  icon: string = "square-2-stack"

  @property()
  value: string

  _copy(_e) {
    navigator.clipboard.writeText(this.value)

    this.shadowRoot.getElementById("copy-icon").style.display = "none"
    this.shadowRoot.getElementById("copy-check").style.display = "block"

    setTimeout(() => {
      this.shadowRoot.getElementById("copy-check").style.display = "none"
      this.shadowRoot.getElementById("copy-icon").style.display = "block"
    }, 2000)
  }

  static styles = css`
    svg {
      width: 1.25rem;
      height: 1.25rem;
    }

    #copy-check {
      display: none;
    }
  `

  protected render() {
    let icon
    switch (this.icon) {
      case "square-2-stack":
        icon = html`
         <svg id="copy-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 8.25V6a2.25 2.25 0 0 0-2.25-2.25H6A2.25 2.25 0 0 0 3.75 6v8.25A2.25 2.25 0 0 0 6 16.5h2.25m8.25-8.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-7.5A2.25 2.25 0 0 1 8.25 18v-1.5m8.25-8.25h-6a2.25 2.25 0 0 0-2.25 2.25v6" />
          </svg>
          `
        break

      case "link":
        icon = html`
          <svg id="copy-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 7.244" />
          </svg>
          `
        break
    }

    return html`
      <div>
        <div style="height: 1.25rem; width: 1.25rem; cursor: pointer;" @click="${this._copy}">
          ${icon}
          <svg id="copy-check" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="rgb(var(--blue-600))">
            <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
          </svg>
        </div>
      </div>
    `
  }
}