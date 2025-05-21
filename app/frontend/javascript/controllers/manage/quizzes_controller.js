import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchForm", "searchInput", "typeSelect", "timeStatusSelect", "courseSelect"
  ]

  search() {
    if (this._searchTimeout) {
      clearTimeout(this._searchTimeout)
    }
    this._searchTimeout = setTimeout(() => {
      this.updateURL()
      this.submitForm()
    }, 300)
  }

  filterByType() {
    this.updateURL()
    this.submitForm()
  }

  filterByTimeStatus() {
    this.updateURL()
    this.submitForm()
  }

  filterByCourse() {
    this.updateURL()
    this.submitForm()
  }

  clearSearch() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
      this.updateURL()
      this.submitForm()
    }
  }

  resetAllFilters() {
    if (this.hasSearchInputTarget) this.searchInputTarget.value = ''
    if (this.hasTypeSelectTarget) this.typeSelectTarget.value = ''
    if (this.hasTimeStatusSelectTarget) this.timeStatusSelectTarget.value = ''
    if (this.hasCourseSelectTarget) this.courseSelectTarget.value = ''
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
