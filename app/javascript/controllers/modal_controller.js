import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
// Простой контроллер для работы с модальным окном
export default class extends Controller {
  connect() {
    // Слушаем загрузку контента в Turbo Frame
    this.setupFrameListener()
  }

  setupFrameListener() {
    const frame = document.querySelector("turbo-frame#equipment-modal-frame")
    if (frame) {
      // Открываем модальное окно, когда контент загружен
      frame.addEventListener("turbo:load", () => {
        this.openModal()
      })
    }
  }

  openModal() {
    const modal = document.getElementById("equipment-modal")
    if (modal) {
      modal.classList.remove("hidden")
    }
  }
}
