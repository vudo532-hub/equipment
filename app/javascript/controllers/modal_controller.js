import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["backdrop", "content"]

  connect() {
    console.log("Modal controller connected")
    this.element.setAttribute("aria-hidden", "true")
    this.element.addEventListener('modal:open', this.open.bind(this))
    
    // Listen for turbo frame content changes
    const frame = document.getElementById('equipment-modal-frame')
    if (frame) {
      frame.addEventListener('turbo:frame-render', () => {
        console.log("Turbo frame rendered, opening modal")
        this.open()
      })
      
      // Also listen for content changes
      const observer = new MutationObserver(() => {
        if (frame.innerHTML.trim() !== '') {
          console.log("Frame content changed, opening modal")
          this.open()
        }
      })
      observer.observe(frame, { childList: true, subtree: true })
    }
  }

  open() {
    console.log("Modal open called")
    this.element.style.display = "block"
    this.element.setAttribute("aria-hidden", "false")
    this.backdropTarget.classList.remove("opacity-0")
    this.backdropTarget.classList.add("opacity-100")
    this.contentTarget.classList.remove("opacity-0", "scale-95")
    this.contentTarget.classList.add("opacity-100", "scale-100")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    console.log("Modal close called")
    this.element.setAttribute("aria-hidden", "true")
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0")
    this.contentTarget.classList.remove("opacity-100", "scale-100")
    this.contentTarget.classList.add("opacity-0", "scale-95")
    document.body.classList.remove("overflow-hidden")
    
    // Hide after animation
    setTimeout(() => {
      console.log("Hiding modal")
      this.element.style.display = "none"
    }, 300)
  }

  // Close modal when clicking on backdrop
  backdropClick(event) {
    console.log("Backdrop clicked")
    if (event.target === this.backdropTarget) {
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
