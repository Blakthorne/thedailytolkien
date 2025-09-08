import { Controller } from "@hotwired/stimulus"

// Makes a table row clickable to navigate to a URL while preserving interactions
// on nested interactive elements (checkboxes, links, buttons, inputs).
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.setAttribute("role", "link")
    this.element.setAttribute("tabindex", "0")
    this.element.style.cursor = "pointer"
    this.onClick = this.onClick.bind(this)
    this.onKey = this.onKey.bind(this)
    this.element.addEventListener("click", this.onClick)
    this.element.addEventListener("keydown", this.onKey)
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick)
    this.element.removeEventListener("keydown", this.onKey)
  }

  onClick(event) {
    if (!this.urlValue) return
    // Ignore clicks on interactive children
    const interactiveSelector = 'a, button, input, select, textarea, label, [role="button"]'
    if (event.target.closest(interactiveSelector)) return
    // Also ignore clicks inside first cell if it contains selection checkbox
    const firstCell = this.element.querySelector("td,th")
    if (firstCell && firstCell.contains(event.target) && firstCell.querySelector("input[type=checkbox]")) return
    window.location = this.urlValue
  }

  onKey(event) {
    if (!this.urlValue) return
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      window.location = this.urlValue
    }
  }
}
