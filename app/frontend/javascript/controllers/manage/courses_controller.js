import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchForm", "searchInput", "categorySelect", "statusSelect", "perPageSelect"
  ]

  connect() {
    console.log("Manage courses controller connected")
  }

  filterByCategory() {
    this.updateURL()
    this.submitForm()
  }

  filterByStatus() {
    this.updateURL()
    this.submitForm()
  }

  changePerPage() {
    this.updateURL()
    this.submitForm()
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

  clearSearch() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
      this.updateURL()
      this.submitForm()
    }
  }

  resetAllFilters() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
    }

    if (this.hasCategorySelectTarget) {
      this.categorySelectTarget.value = ''
    }

    if (this.hasStatusSelectTarget) {
      this.statusSelectTarget.value = ''
    }

    this.updateURL()
    this.submitForm()
  }

  updateURL() {
    if (!this.hasSearchFormTarget) return

    const formData = new FormData(this.searchFormTarget)
    const url = new URL(window.location.href)
    const params = url.searchParams

    Array.from(params.keys()).forEach(key => {
      if (key !== 'authenticity_token') {
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
    if (this.hasSearchFormTarget) {
      this.searchFormTarget.requestSubmit()
    }
  }
}
