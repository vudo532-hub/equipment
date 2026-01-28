import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static outlets = ["turbo-frame"]
  
  connect() {
    // Modal automatically opens when content is loaded via Turbo Stream
    this.observeFrameChanges()
  }

  disconnect() {
    this.removeFrameObserver()
  }

  // Automatically open modal when frame content changes
  observeFrameChanges() {
    const frame = document.querySelector("turbo-frame#equipment-modal-frame")
    if (frame) {
      frame.addEventListener("turbo:load", () => this.open())
    }
  }

  removeFrameObserver() {
    const frame = document.querySelector("turbo-frame#equipment-modal-frame")
    if (frame) {
      frame.removeEventListener("turbo:load", () => this.open())
    }
  }

  open() {
    this.element.classList.remove('hidden')
    // Add smooth transition
    this.element.classList.add('opacity-100')
    this.element.classList.remove('opacity-0')
    document.body.classList.add('overflow-hidden')
  }

  close() {
    this.element.classList.add('hidden')
    this.element.classList.remove('opacity-100')
    this.element.classList.add('opacity-0')
    document.body.classList.remove('overflow-hidden')
    
    // Clear modal frame content after closing
    const frame = document.querySelector("turbo-frame#equipment-modal-frame")
    if (frame) {
      frame.innerHTML = ""
    }
  }

  // Close modal on escape key
  escapeKey(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  // Close modal when clicking outside (on the backdrop)
  closeOnBackdropClick(event) {
    if (event.target === this.element) {
      this.close()
    }
  }
}
