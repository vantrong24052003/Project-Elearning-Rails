import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.showTab(0)
  }

  switch(event) {
    event.preventDefault()
    const button = event.currentTarget
    const tabIndex = this.tabTargets.indexOf(button)
    this.showTab(tabIndex)
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      const panel = this.panelTargets[i]
      if (i === index) {
        tab.classList.add("border-b-2", "border-purple-500", "text-purple-500")
        tab.classList.remove("text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
        panel.classList.remove("hidden")
      } else {
        tab.classList.remove("border-b-2", "border-purple-500", "text-purple-500")
        tab.classList.add("text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
        panel.classList.add("hidden")
      }
    })
  }
}
