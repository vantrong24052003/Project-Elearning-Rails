import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchForm", "searchInput", "typeSelect", "timeStatusSelect", "courseSelect", "perPageSelect"
  ]

  search() {
    if (this._searchTimeout) {
      clearTimeout(this._searchTimeout)
    }
    this._searchTimeout = setTimeout(() => {
      this.submitForm()
    }, 300)
  }

  filterByType() {
    this.submitForm()
  }

  filterByTimeStatus() {
    this.submitForm()
  }

  filterByCourse() {
    this.submitForm()
  }

  changePerPage() {
    this.updateURL()
    this.submitForm()
  }

  clearSearch() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
      this.submitForm()
    }
  }

  resetAllFilters() {
    if (this.hasSearchInputTarget) this.searchInputTarget.value = ''
    if (this.hasTypeSelectTarget) this.typeSelectTarget.value = ''
    if (this.hasTimeStatusSelectTarget) this.timeStatusSelectTarget.value = ''
    if (this.hasCourseSelectTarget) this.courseSelectTarget.value = ''
    this.submitForm()
  }

  submitForm() {
    if (this.hasSearchFormTarget) {
      this.searchFormTarget.requestSubmit()
    }
  }

  updateURL() {
    if (!this.hasSearchFormTarget) return

    const formData = new FormData(this.searchFormTarget)
    const url = new URL(window.location.href)
    const params = url.searchParams

    // Clear existing params except authenticity_token
    Array.from(params.keys()).forEach(key => {
      if (key !== 'authenticity_token') {
        params.delete(key)
      }
    })

    // Add form data to URL params
    for (const [key, value] of formData.entries()) {
      if (key !== 'authenticity_token' && value) {
        params.set(key, value)
      }
    }

    // Update browser URL without page reload
    window.history.pushState({}, '', url.toString())
  }
}
