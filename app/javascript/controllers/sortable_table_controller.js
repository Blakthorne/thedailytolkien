import { Controller } from "@hotwired/stimulus"

// Progressive enhancement sortable table with no external deps.
// Click header cells to sort; updates aria-sort for a11y.
export default class extends Controller {
  static targets = ["header"]

  connect() {
    this.thead = this.element.querySelector("thead")
    this.tbody = this.element.querySelector("tbody")
    if (!this.thead || !this.tbody) return

    // Attach click handlers to header cells
    this.headers = Array.from(this.thead.querySelectorAll("th"))
    this.headers.forEach((th, index) => {
      th.style.cursor = "pointer"
      th.setAttribute("role", "columnheader")
      th.setAttribute("tabindex", "0")
      if (!th.hasAttribute("aria-sort")) th.setAttribute("aria-sort", "none")
      th.addEventListener("click", () => this.sortBy(index, th))
      th.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault()
          this.sortBy(index, th)
        }
      })
    })
  }

  sortBy(index, th) {
    const type = th.dataset.type || "text"
    const current = th.getAttribute("aria-sort")
    const direction = current === "ascending" ? "descending" : "ascending"

    // Reset aria-sort on other headers
    this.headers.forEach(h => {
      if (h !== th) h.removeAttribute("aria-sort")
    })
    th.setAttribute("aria-sort", direction)

    const rows = Array.from(this.tbody.querySelectorAll("tr"))
    const multiplier = direction === "ascending" ? 1 : -1

    rows.sort((a, b) => {
      const aCell = a.children[index]
      const bCell = b.children[index]
      const aVal = this.cellValue(aCell, type)
      const bVal = this.cellValue(bCell, type)
      if (aVal < bVal) return -1 * multiplier
      if (aVal > bVal) return 1 * multiplier
      return 0
    })

    // Re-append rows
    rows.forEach(r => this.tbody.appendChild(r))
  }

  cellValue(cell, type) {
    if (!cell) return ""
    // Prefer data-sort-value if provided
    if (cell.hasAttribute("data-sort-value")) {
      const raw = cell.getAttribute("data-sort-value") || ""
      if (raw !== "") return this.coerce(raw, type)
      // fall through to text if empty
    }
    const text = (cell.innerText || cell.textContent || "").trim()
    return this.coerce(text, type)
  }

  coerce(value, type) {
    switch (type) {
      case "number":
        return parseFloat(value.replace(/[^0-9.-]/g, "")) || 0
      case "date":
        return new Date(value).getTime() || 0
      default:
        return value.toLowerCase()
    }
  }
}
