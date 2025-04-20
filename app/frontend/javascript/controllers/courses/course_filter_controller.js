import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchForm", "searchInput", "categoryInput",
    "minPriceInput", "maxPriceInput", "filterModal",
    "searchFilter", "categoryFilter", "priceFilter",
    "categorySelect", "searchTerm", "categoryName",
    "priceMin", "priceMax"
  ]

  connect() {
    this.searchTimeout = null
  }

  toggleFilterModal() {
    this.filterModalTarget.classList.toggle("hidden")
  }

  searchWithDebounce() {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      this.searchFormTarget.requestSubmit()
    }, 400)
  }

  updateCategoryFilter() {
    const categoryId = this.categorySelectTarget.value
    this.categoryInputTarget.value = categoryId
    this.searchFormTarget.requestSubmit()
  }

  updatePriceRange(event) {
    this.minPriceInputTarget.value = event.detail.min
    this.maxPriceInputTarget.value = event.detail.max
    this.priceMinTarget.textContent = event.detail.min
    this.priceMaxTarget.textContent = event.detail.max
    this.searchFormTarget.requestSubmit()
  }

  clearSearch() {
    this.searchInputTarget.value = ""
    this.searchFormTarget.requestSubmit()
  }

  clearCategoryFilter() {
    this.categoryInputTarget.value = ""
    this.categorySelectTarget.value = ""
    this.searchFormTarget.requestSubmit()
  }

  clearPriceFilter() {
    this.minPriceInputTarget.value = ""
    this.maxPriceInputTarget.value = ""
    this.searchFormTarget.requestSubmit()
  }

  applyFilters() {
    this.searchFormTarget.requestSubmit()
    this.toggleFilterModal()
  }

  resetFilters() {
    this.searchInputTarget.value = ""
    this.categoryInputTarget.value = ""
    this.minPriceInputTarget.value = ""
    this.maxPriceInputTarget.value = ""
    this.categorySelectTarget.value = ""
    this.searchFormTarget.requestSubmit()
    this.toggleFilterModal()
  }
}
