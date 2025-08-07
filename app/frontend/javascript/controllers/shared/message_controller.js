import { Controller } from "@hotwired/stimulus"
import { MessageService } from "../../services/message_service"

export default class extends Controller {
  static values = {
    autoClose: { type: Boolean, default: true },
    duration: { type: Number, default: 5000 }
  }

  connect() {
    this.displayFlashMessages()
    this.setupEventListeners()
  }

  disconnect() {
    document.removeEventListener('turbo:before-cache', this.handleBeforeCache)
    document.removeEventListener('turbo:load', this.handleTurboLoad)
    window.removeEventListener('pageshow', this.handlePageShow)
  }

  setupEventListeners() {
    this.handleBeforeCache = this.handleBeforeCache.bind(this)
    this.handleTurboLoad = this.handleTurboLoad.bind(this)
    this.handlePageShow = this.handlePageShow.bind(this)

    document.addEventListener('turbo:before-cache', this.handleBeforeCache)
    document.addEventListener('turbo:load', this.handleTurboLoad)
    window.addEventListener('pageshow', this.handlePageShow)
  }

  handleBeforeCache() {
    MessageService.clearAll()
  }

  handleTurboLoad() {
    MessageService.clearAll()
  }

  handlePageShow(event) {
    if (event.persisted) {
      MessageService.forceClear()
    }
  }

  displayFlashMessages() {
    const notice = this.element.dataset.notice
    const alert = this.element.dataset.alert

    if (notice) {
      MessageService.success(notice, this.durationValue)
      this.clearFlashData('notice')
    }

    if (alert) {
      MessageService.error(alert, this.durationValue)
      this.clearFlashData('alert')
    }
  }

  clearFlashData(type) {
    this.element.dataset[type] = ''
  }
}
