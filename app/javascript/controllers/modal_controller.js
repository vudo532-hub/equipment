import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
// Простой контроллер для работы с модальным окном
export default class extends Controller {
  connect() {
    // Слушаем загрузку контента в Turbo Frame
    this.setupFrameListener()
    // Слушаем Turbo событие для закрытия модального окна
    this.setupModalCloseListener()
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

  setupModalCloseListener() {
    document.addEventListener("turbo:submit-end", (event) => {
      // Закрываем модальное окно после успешной формы
      if (event.detail.success) {
        this.closeModal()
      }
    })
    
    // Слушаем пользовательское событие close:modal от turbo_stream.dispatch
    window.addEventListener("close:modal", () => {
      this.closeModal()
    })
  }

  openModal() {
    const modal = document.getElementById("equipment-modal")
    if (modal) {
      modal.classList.remove("hidden")
      // Блокируем прокрутку body
      document.body.style.overflow = 'hidden'
    }
  }

  closeModal() {
    const modal = document.getElementById("equipment-modal")
    if (modal) {
      modal.classList.add("hidden")
      // Восстанавливаем прокрутку body
      document.body.style.overflow = ''
    }
    // Очищаем содержимое фрейма
    const frame = document.querySelector("turbo-frame#equipment-modal-frame")
    if (frame) {
      frame.innerHTML = ''
    }
  }
}

