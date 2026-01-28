import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
// Простой контроллер для работы с модальным окном
export default class extends Controller {
  connect() {
    // Слушаем загрузку контента в Turbo Frame
    this.setupFrameListener()
    // Слушаем успешную отправку формы
    this.setupFormSubmitListener()
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

  setupFormSubmitListener() {
    // Слушаем успешную отправку формы
    document.addEventListener("turbo:submit-end", (event) => {
      // Проверяем, что форма успешно отправлена
      if (event.detail && event.detail.success) {
        // Закрываем модальное окно после успешной отправки
        setTimeout(() => {
          this.closeModal()
        }, 100)
      }
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

