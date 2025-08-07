import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filterForm", "searchInput", "instructorSelect", "statusSelect",
    "moderationStatusSelect", "courseSelect", "dateFromInput", "dateToInput", "perPageSelect"
  ]

  connect() {
    console.log("Video filter controller connected")
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

  filterByInstructor() {
    this.updateURL()
    this.submitForm()
  }

  filterByStatus() {
    this.updateURL()
    this.submitForm()
  }

  filterByModerationStatus() {
    this.updateURL()
    this.submitForm()
  }

  filterByCourse() {
    this.updateURL()
    this.submitForm()
  }

  filterByDate() {
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

    if (this.hasInstructorSelectTarget) {
      this.instructorSelectTarget.value = ""
    }

    if (this.hasStatusSelectTarget) {
      this.statusSelectTarget.value = ""
    }

    if (this.hasModerationStatusSelectTarget) {
      this.moderationStatusSelectTarget.value = ""
    }

    if (this.hasCourseSelectTarget) {
      this.courseSelectTarget.value = ""
    }

    if (this.hasDateFromInputTarget) {
      this.dateFromInputTarget.value = ""
    }

    if (this.hasDateToInputTarget) {
      this.dateToInputTarget.value = ""
    }

    if (this.hasPerPageSelectTarget) {
      this.perPageSelectTarget.value = "10"
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
