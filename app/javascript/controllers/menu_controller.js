import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "button"]

  toggle() {
    const open = this.buttonTarget.getAttribute("aria-expanded") !== "true"
    this.buttonTarget.setAttribute("aria-expanded", String(open))
    this.panelTarget.classList.toggle("is-open", open)
  }

  close() {
    if (!this.hasButtonTarget || !this.hasPanelTarget) return
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.panelTarget.classList.remove("is-open")
  }
}
