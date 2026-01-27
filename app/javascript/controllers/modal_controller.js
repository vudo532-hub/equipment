import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    console.log("Modal controller connected")
  }

  open() {
    console.log("Modal open called")
    this.element.classList.remove('hidden')
    document.body.classList.add('overflow-hidden')
  }

  close() {
    console.log("Modal close called")
    this.element.classList.add('hidden')
    document.body.classList.remove('overflow-hidden')
  }

  // Close modal on escape key
  escapeKey(event) {
    console.log("Escape key pressed")
    if (event.key === "Escape") {
      this.close()
    }
  }
}
