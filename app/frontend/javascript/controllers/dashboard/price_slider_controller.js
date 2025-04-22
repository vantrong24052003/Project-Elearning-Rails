import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["minSlider", "maxSlider", "range"]

  static values = {
    min: Number,
    max: Number,
    step: Number
  }

  connect() {
    this.updateSliderDisplay()

    this.minSliderTarget.addEventListener('mousedown', this.setupDragEvents.bind(this))
    this.maxSliderTarget.addEventListener('mousedown', this.setupDragEvents.bind(this))

    this.minSliderTarget.addEventListener('touchstart', this.setupTouchEvents.bind(this), { passive: true })
    this.maxSliderTarget.addEventListener('touchstart', this.setupTouchEvents.bind(this), { passive: true })
  }

  setupDragEvents(e) {
    document.addEventListener('mousemove', this.updateValues.bind(this))
    document.addEventListener('mouseup', this.removeDragEvents.bind(this))
  }

  setupTouchEvents(e) {
    document.addEventListener('touchmove', this.updateValues.bind(this), { passive: true })
    document.addEventListener('touchend', this.removeTouchEvents.bind(this))
  }

  removeDragEvents() {
    document.removeEventListener('mousemove', this.updateValues.bind(this))
    document.removeEventListener('mouseup', this.removeDragEvents.bind(this))
  }

  removeTouchEvents() {
    document.removeEventListener('touchmove', this.updateValues.bind(this))
    document.removeEventListener('touchend', this.removeTouchEvents.bind(this))
  }

  updateValues() {
    let minValue = parseInt(this.minSliderTarget.value)
    let maxValue = parseInt(this.maxSliderTarget.value)

    if (minValue >= maxValue) {
      minValue = maxValue - this.stepValue
      this.minSliderTarget.value = minValue
    }

    this.updateSliderDisplay()

    this.dispatch("change", {
      detail: {
        min: minValue,
        max: maxValue
      }
    })
  }

  updateSliderDisplay() {
    const percent = (value) => (value / this.maxValue) * 100
    const minPercent = percent(this.minSliderTarget.value)
    const maxPercent = 100 - percent(this.maxSliderTarget.value)

    this.rangeTarget.style.left = `${minPercent}%`
    this.rangeTarget.style.right = `${100 - percent(this.maxSliderTarget.value)}%`

    const formatter = new Intl.NumberFormat('vi-VN')

    const minDisplay = document.querySelector('[data-price-filter-target="priceMinDisplay"]')
    const maxDisplay = document.querySelector('[data-price-filter-target="priceMaxDisplay"]')

    if (minDisplay) {
      minDisplay.textContent = `${formatter.format(this.minSliderTarget.value)}đ`
    }

    if (maxDisplay) {
      maxDisplay.textContent = `${formatter.format(this.maxSliderTarget.value)}đ`
    }
  }
}
