import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchForm", "searchInput", "categoryInput", "minPriceInput", "maxPriceInput",
                   "categorySelect", "sortSelect", "activeFilters", "searchFilter", "categoryFilter",
                   "priceFilter", "sortFilter", "searchTerm", "categoryName", "priceFilterText",
                   "sortText", "filterModal", "modalCategorySelect", "modalPriceMin", "modalPriceMax"]

  initialize() {
    this.debounceTimer = null
  }

  connect() {
    console.log("Course filter controller connected")
  }

  submit(event) {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      const formData = new FormData(this.element)
      const url = new URL(this.element.action)

      for (let [key, value] of formData.entries()) {
        if (value) url.searchParams.append(key, value)
      }

      Turbo.visit(url.toString(), {
        frame: this.element.dataset.turboFrame,
        action: 'replace'
      })
    }, 300)
  }

  searchWithDebounce(event) {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.searchFormTarget.requestSubmit()
    }, 500)
  }

  updateCategoryFilter(event) {
    const selectedCategoryId = event.target.value
    this.categoryInputTarget.value = selectedCategoryId
    this.searchFormTarget.requestSubmit()
  }

  applySortFilter(event) {
    const selectedSort = event.target.value
    const sortByInput = this.searchFormTarget.querySelector('input[name="sort_by"]')
    if (sortByInput) {
      sortByInput.value = selectedSort
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

  applyModalFilters() {
    const categoryId = this.modalCategorySelectTarget.value
    const minPrice = parseInt(document.querySelector('[data-dashboard--price-slider-target="minSlider"]').value)
    const maxPrice = parseInt(document.querySelector('[data-dashboard--price-slider-target="maxSlider"]').value)

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
    document.querySelector('[data-dashboard--price-slider-target="minSlider"]').value = 0
    document.querySelector('[data-dashboard--price-slider-target="maxSlider"]').value = 1000000

    this.searchFormTarget.requestSubmit()
    this.toggleFilterModal()
  }
}
