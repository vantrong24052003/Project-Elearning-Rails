import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["importForm"]

  connect() {
    console.log('Questions import controller connected')
  }

  toggleImportForm() {
    this.importFormTarget.classList.toggle('hidden')

  }
}
