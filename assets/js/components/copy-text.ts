import { html, css, LitElement } from "lit"
import { customElement, property } from "lit/decorators.js"

@customElement("copy-text")
export default class CopyText extends LitElement {
  @property()
  label: string

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

    .label {
      margin-top: 1rem;
      color: var(--alpha-64);
      font-size: 0.75rem;
      text-transform: uppercase;
    }

    .copy-container {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 1rem;
      margin-top: 0.5rem;
      border-radius: 0.25rem;
      background-color: var(--surface-3);
    }

    .value {
      color: var(--gray-900);
      font-size: 1rem;
      overflow-x: scroll;
      margin-right: 0.5rem;
      word-break: break-all;
    }

    #copy-check {
      display: none;
    }
  `

  protected render() {
    return html`
      <div class="label">${this.label}</div>
        <div class="copy-container">
          <code class="value">
            ${this.value}
          </code>
          <div style="height: 1.25rem; width: 1.25rem; cursor: pointer;" @click="${this._copy}">
            <svg id="copy-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 8.25V6a2.25 2.25 0 0 0-2.25-2.25H6A2.25 2.25 0 0 0 3.75 6v8.25A2.25 2.25 0 0 0 6 16.5h2.25m8.25-8.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-7.5A2.25 2.25 0 0 1 8.25 18v-1.5m8.25-8.25h-6a2.25 2.25 0 0 0-2.25 2.25v6" />
            </svg>
            <svg id="copy-check" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="rgb(var(--blue-600))">
              <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
            </svg>
          </div>
        </div>
      </div>
    `
  }
}