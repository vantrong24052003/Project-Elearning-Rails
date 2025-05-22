import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filterForm", "searchInput", "statusSelect", "paymentMethodSelect",
    "paidAtSelect", "perPageSelect"
  ]

  connect() {
    console.log("Enrollments filter controller connected")
  }

  search() {
    if (this._searchTimeout) {
      clearTimeout(this._searchTimeout)
    }

    this._searchTimeout = setTimeout(() => {
      this.updateURL()
      this.submitForm()
    }, 300)
  }

  filterByStatus() {
    this.updateURL()
    this.submitForm()
  }

  filterByPaymentMethod() {
    this.updateURL()
    this.submitForm()
  }

  filterByPaidAt() {
    this.updateURL()
    this.submitForm()
  }

  changePerPage() {
    this.updateURL()
    this.submitForm()
  }

  resetFilters() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ""
    }

    if (this.hasStatusSelectTarget) {
      this.statusSelectTarget.value = ""
    }

    if (this.hasPaymentMethodSelectTarget) {
      this.paymentMethodSelectTarget.value = ""
    }

    if (this.hasPaidAtSelectTarget) {
      this.paidAtSelectTarget.value = ""
    }

    this.updateURL()
    this.submitForm()
  }

  updateURL() {
    if (!this.hasFilterFormTarget) return

    const formData = new FormData(this.filterFormTarget)
    const url = new URL(window.location.href)
    const params = url.searchParams

    Array.from(params.keys()).forEach(key => {
      if (key !== 'authenticity_token' && key !== 'page') {
        params.delete(key)
      }
    })

    for (const [key, value] of formData.entries()) {
      if (key !== 'authenticity_token' && value) {
        params.set(key, value)
      }
    }

    window.history.pushState({}, '', url.toString())
  }

  submitForm() {
    if (this.hasFilterFormTarget) {
      this.filterFormTarget.requestSubmit()
    }
  }
}
