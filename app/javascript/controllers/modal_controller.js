import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["backdrop", "content"]

  connect() {
    this.element.setAttribute("aria-hidden", "true")
  }

  open() {
    this.element.setAttribute("aria-hidden", "false")
    this.backdropTarget.classList.remove("opacity-0")
    this.backdropTarget.classList.add("opacity-100")
    this.contentTarget.classList.remove("opacity-0", "scale-95")
    this.contentTarget.classList.add("opacity-100", "scale-100")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.element.setAttribute("aria-hidden", "true")
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0")
    this.contentTarget.classList.remove("opacity-100", "scale-100")
    this.contentTarget.classList.add("opacity-0", "scale-95")
    document.body.classList.remove("overflow-hidden")
  }

  // Close modal when clicking on backdrop
  backdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  // Close modal on escape key
  escapeKey(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
