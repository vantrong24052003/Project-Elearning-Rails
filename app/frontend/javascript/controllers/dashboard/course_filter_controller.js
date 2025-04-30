import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchForm", "searchInput", "categoryInput", "minPriceInput", "maxPriceInput",
                   "categorySelect", "sortSelect", "activeFilters", "searchFilter", "categoryFilter",
                   "priceFilter", "sortFilter", "searchTerm", "categoryName", "priceFilterText",
                   "sortText", "filterModal", "modalCategorySelect", "modalPriceMin", "modalPriceMax"]

  connect() {
    document.addEventListener("turbo:frame-render", this.updateURLFromFrame.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:frame-render", this.updateURLFromFrame.bind(this))
  }

  updateURLFromFrame(event) {
    if (event.target.id === "course-results") {
      const frameURL = event.target.src
      if (!frameURL) return

      const urlParts = frameURL.split('?')
      if (urlParts.length < 2) return

      const newURL = `${window.location.pathname}?${urlParts[1]}`
      window.history.replaceState({ path: newURL }, '', newURL)
    }
  }

  searchWithDebounce(event) {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.searchFormTarget.requestSubmit()
    }, 500)
  }

  updateCategoryFilter(event) {
    this.categoryInputTarget.value = event.target.value
    this.searchFormTarget.requestSubmit()
  }

  applySortFilter(event) {
    const sortByInput = this.searchFormTarget.querySelector('input[name="sort_by"]')
    if (sortByInput) {
      sortByInput.value = event.target.value
      this.searchFormTarget.requestSubmit()
    }
  }

  toggleFilterModal() {
    this.filterModalTarget.classList.toggle('hidden')
  }

  updateModalPriceRange(event) {
    const { min, max } = event.detail
    this.modalPriceMinTarget.textContent = new Intl.NumberFormat().format(min)
    this.modalPriceMaxTarget.textContent = new Intl.NumberFormat().format(max)
  }

  updateRangeSliders(event) {
    const minSlider = document.getElementById('minPriceSlider')
    const maxSlider = document.getElementById('maxPriceSlider')
    const rangeTrack = document.getElementById('rangeTrack')

    let minValue = parseInt(minSlider.value)
    let maxValue = parseInt(maxSlider.value)

    if (event.target.id === 'minPriceSlider') {
      if (minValue > maxValue) {
        minValue = maxValue
        minSlider.value = minValue
      }
    } else {
      if (maxValue < minValue) {
        maxValue = minValue
        maxSlider.value = maxValue
      }
    }

    const minPercent = (minValue / minSlider.max) * 100
    const maxPercent = 100 - (maxValue / maxSlider.max) * 100

    if (rangeTrack) {
      rangeTrack.style.left = `${minPercent}%`
      rangeTrack.style.right = `${maxPercent}%`
    }

    if (this.hasModalPriceMinTarget) {
      this.modalPriceMinTarget.textContent = new Intl.NumberFormat().format(minValue)
    }

    if (this.hasModalPriceMaxTarget) {
      this.modalPriceMaxTarget.textContent = new Intl.NumberFormat().format(maxValue)
    }
  }

  applyModalFilters() {
    const categoryId = this.modalCategorySelectTarget.value

    const minSlider = document.getElementById('minPriceSlider')
    const maxSlider = document.getElementById('maxPriceSlider')

    const minPrice = minSlider ? parseInt(minSlider.value) : 0
    const maxPrice = maxSlider ? parseInt(maxSlider.value) : 1000000

    this.categoryInputTarget.value = categoryId
    this.minPriceInputTarget.value = minPrice
    this.maxPriceInputTarget.value = maxPrice

    this.searchFormTarget.requestSubmit()
    this.toggleFilterModal()
  }

  clearSearch() {
    this.searchInputTarget.value = ''
    this.searchFormTarget.requestSubmit()
  }

  clearCategoryFilter() {
    this.categoryInputTarget.value = ''
    this.searchFormTarget.requestSubmit()
  }

  clearPriceFilter() {
    this.minPriceInputTarget.value = ''
    this.maxPriceInputTarget.value = ''
    this.searchFormTarget.requestSubmit()
  }

  clearSortFilter() {
    const sortByInput = this.searchFormTarget.querySelector('input[name="sort_by"]')
    if (sortByInput) {
      sortByInput.value = ''
      this.searchFormTarget.requestSubmit()
    }
  }

  resetFilters() {
    this.categoryInputTarget.value = ''
    this.minPriceInputTarget.value = ''
    this.maxPriceInputTarget.value = ''
    this.searchInputTarget.value = ''

    const sortByInput = this.searchFormTarget.querySelector('input[name="sort_by"]')
    if (sortByInput) sortByInput.value = ''

    this.modalCategorySelectTarget.value = ''

    const minSlider = document.getElementById('minPriceSlider')
    const maxSlider = document.getElementById('maxPriceSlider')
    const rangeTrack = document.getElementById('rangeTrack')

    if (minSlider) minSlider.value = 0
    if (maxSlider) maxSlider.value = 1000000

    if (rangeTrack) {
      rangeTrack.style.left = '0%'
      rangeTrack.style.right = '0%'
    }

    if (this.hasModalPriceMinTarget) {
      this.modalPriceMinTarget.textContent = '0'
    }

    if (this.hasModalPriceMaxTarget) {
      this.modalPriceMaxTarget.textContent = '1,000,000'
    }

    this.searchFormTarget.requestSubmit()
    this.toggleFilterModal()
  }
}
