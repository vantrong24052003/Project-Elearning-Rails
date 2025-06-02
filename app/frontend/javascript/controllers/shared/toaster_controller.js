import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.createStyles()
    this.displayFlash()
    this.setupListeners()
  }

  disconnect() {
    document.removeEventListener('toast:show', this.handleToastEvent)
  }

  setupListeners() {
    this.handleToastEvent = this.handleToastEvent.bind(this)
    document.addEventListener('toast:show', this.handleToastEvent)
  }

  handleToastEvent(event) {
    const { message, type, duration } = event.detail
    this.showToast(message, type, duration)
  }

  createStyles() {
    if (document.getElementById('toast-system-styles')) return

    const style = document.createElement('style')
    style.id = 'toast-system-styles'
    style.textContent = `
      .toast-enter {
        opacity: 0;
        transform: translateX(20px);
      }
      .toast-enter-active {
        opacity: 1;
        transform: translateX(0);
        transition: opacity 300ms, transform 300ms;
      }
      .toast-exit {
        opacity: 1;
      }
      .toast-exit-active {
        opacity: 0;
        transform: translateX(20px);
        transition: opacity 300ms, transform 300ms;
      }
    `
    document.head.appendChild(style)
  }

  displayFlash() {
    const notice = this.element.dataset.notice
    const alert = this.element.dataset.alert

    if (notice) {
      this.showToast(notice, "success")
    }

    if (alert) {
      this.showToast(alert, "error")
    }
  }

  showToast(message, type = "success", duration = 5000) {
    const toast = document.createElement("div")
    let bgColor, icon

    switch(type) {
      case "success":
        bgColor = "bg-green-600"
        icon = `<svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
        </svg>`
        break
      case "error":
        bgColor = "bg-red-600"
        icon = `<svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
          <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
        </svg>`
        break
      case "warning":
        bgColor = "bg-yellow-600"
        icon = `<svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
          <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path>
        </svg>`
        break
      default:
        bgColor = "bg-gray-700"
        icon = `<svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2h-1V9z" clip-rule="evenodd"></path>
        </svg>`
    }

    toast.className = `flex items-center p-4 mb-4 w-full max-w-xs text-white ${bgColor} rounded-lg shadow toast-enter cursor-pointer`
    toast.setAttribute("role", "alert")
    toast.id = `toast-${type}-${Date.now()}`
    toast.setAttribute("data-action", "click->shared--toaster#closeToast")
    toast.setAttribute("data-toast-id", toast.id)

    toast.innerHTML = `
      <div class="flex items-center">
        <div class="flex-shrink-0 mr-3">
          ${icon}
        </div>
        <div class="text-sm font-medium">${message}</div>
      </div>
    `

    const toastContainer = document.getElementById('toast-container')
    if (!toastContainer) {
      const newContainer = document.createElement('div')
      newContainer.id = 'toast-container'
      newContainer.className = 'fixed top-4 right-4 z-50 flex flex-col gap-2'
      document.body.appendChild(newContainer)
      newContainer.appendChild(toast)
    } else {
      toastContainer.appendChild(toast)
    }

    setTimeout(() => {
      toast.classList.remove('toast-enter')
      toast.classList.add('toast-enter-active')
    }, 10)

    setTimeout(() => {
      this.closeToast({ currentTarget: { dataset: { toastId: toast.id } } })
    }, duration)

    return toast.id
  }

  closeToast(event) {
    const id = event.currentTarget.dataset.toastId
    const toast = document.getElementById(id)

    if (toast) {
      toast.classList.remove('toast-enter-active')
      toast.classList.add('toast-exit')

      setTimeout(() => {
        toast.classList.add('toast-exit-active')
        setTimeout(() => {
          if (toast.parentNode) {
            toast.parentNode.removeChild(toast)
          }

          const container = document.getElementById('toast-container')
          if (container && container.children.length === 0) {
            container.remove()
          }
        }, 300)
      }, 10)
    }
  }
}
