import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    console.log("Modal controller connected")
    this.element.setAttribute("aria-hidden", "true")
    this.element.style.display = "none"
    
    // Check if modal should be open on connect
    if (this.element.style.display === "block" || this.element.getAttribute("aria-hidden") === "false") {
      console.log("Modal is already open, setting up properly")
      this.showModalElements()
    }
  }

  open() {
    console.log("Modal open called")
    this.showModalElements()
  }

  showModalElements() {
    const backdrop = this.element.querySelector('[data-modal-target="backdrop"]')
    const content = this.element.querySelector('[data-modal-target="content"]')
    
    if (backdrop && content) {
      this.element.style.display = "block"
      this.element.setAttribute("aria-hidden", "false")
      backdrop.classList.remove("opacity-0")
      backdrop.classList.add("opacity-100")
      content.classList.remove("opacity-0", "scale-95")
      content.classList.add("opacity-100", "scale-100")
      document.body.classList.add("overflow-hidden")
    } else {
      console.error("Could not find backdrop or content elements")
    }
  }

  close() {
    console.log("Modal close called")
    const backdrop = this.element.querySelector('[data-modal-target="backdrop"]')
    const content = this.element.querySelector('[data-modal-target="content"]')
    
    if (backdrop && content) {
      this.element.setAttribute("aria-hidden", "true")
      backdrop.classList.remove("opacity-100")
      backdrop.classList.add("opacity-0")
      content.classList.remove("opacity-100", "scale-100")
      content.classList.add("opacity-0", "scale-95")
      document.body.classList.remove("overflow-hidden")
      
      // Hide after animation
      setTimeout(() => {
        console.log("Hiding modal")
        this.element.style.display = "none"
      }, 300)
    }
  }

  // Close modal when clicking on backdrop
  backdropClick(event) {
    console.log("Backdrop clicked")
    const backdrop = this.element.querySelector('[data-modal-target="backdrop"]')
    if (event.target === backdrop) {
      this.close()
    }
  }

  // Close modal on escape key
  escapeKey(event) {
    console.log("Escape key pressed")
    if (event.key === "Escape") {
      this.close()
    }
  }
}
