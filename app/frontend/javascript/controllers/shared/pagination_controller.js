import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pageLink"]

  connect() {
    console.log("Pagination controller connected")
  }

  updateURL(event) {
    const link = event.currentTarget
    const url = new URL(link.href)
    const params = url.searchParams
    const currentUrl = new URL(window.location.href)
    currentUrl.searchParams.set('page', params.get('page'))

    window.history.pushState({}, '', currentUrl.toString())
  }
}
