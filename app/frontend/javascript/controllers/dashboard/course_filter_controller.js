import { Controller } from "@hotwired/stimulus"
import { updateURL, clearURLAndSubmit, closeModal, openModal, formatPrice } from "../shared/heplper.js"

export default class extends Controller {
  static targets = [
    "searchForm", "searchInput", "categoryInput", "minPriceInput", "maxPriceInput",
    "categorySelect", "sortSelect", "minSlider", "maxSlider", "range",
    "modalCategorySelect", "modalPriceMin", "modalPriceMax", "sortByInput"
  ]

  connect() {
    this.updateSliderValues()
  }

  searchWithDebounce() {
    if (this._searchTimeout) {
      clearTimeout(this._searchTimeout)
    }

    this._searchTimeout = setTimeout(() => {
      updateURL(this.searchFormTarget, () => this.searchFormTarget.requestSubmit())
    }, 300)
  }

  updateCategoryFilter(event) {
    if (this.hasCategoryInputTarget) {
      const selectedValue = event.target.value
      if (selectedValue === '') {
        this.categoryInputTarget.value = 'all_categories'
      } else {
        this.categoryInputTarget.value = selectedValue
      }
    }
    updateURL(this.searchFormTarget, () => this.searchFormTarget.requestSubmit())
  }

  applySortFilter() {
    if (this.hasSortSelectTarget && this.hasSortByInputTarget) {
      this.sortByInputTarget.value = this.sortSelectTarget.value
    }

    updateURL(this.searchFormTarget, () => this.searchFormTarget.requestSubmit())
  }

  updateSliderValues(event) {
  updateSliderValues(event) {
    if (!this.hasMinSliderTarget || !this.hasMaxSliderTarget) return

    let minValue = parseInt(this.minSliderTarget.value)
    let maxValue = parseInt(this.maxSliderTarget.value)

    if (minValue >= maxValue) {
      const movedMin = event && event.target === this.minSliderTarget
      if (movedMin) {
      const movedMin = event && event.target === this.minSliderTarget
      if (movedMin) {
        minValue = maxValue - 50000
        this.minSliderTarget.value = minValue
      } else {
        maxValue = minValue + 50000
        this.maxSliderTarget.value = maxValue
      }
    }

    if (this.hasModalPriceMinTarget) {
      this.modalPriceMinTarget.textContent = formatPrice(minValue)
    }

    if (this.hasModalPriceMaxTarget) {
      this.modalPriceMaxTarget.textContent = formatPrice(maxValue)
    }

    this.updateSliderRangeUI(minValue, maxValue)
  }

  updateSliderRangeUI(min, max) {
    if (!this.hasRangeTarget) return

    const minRange = 0
    const maxRange = 1000000

    const leftPercent = ((min - minRange) / (maxRange - minRange)) * 100
    const rightPercent = 100 - ((max - minRange) / (maxRange - minRange)) * 100

    this.rangeTarget.style.left = `${leftPercent}%`
    this.rangeTarget.style.right = `${rightPercent}%`
  }

  applyModalFilters() {
    if (this.hasModalCategorySelectTarget && this.hasCategoryInputTarget) {
      this.categoryInputTarget.value = this.modalCategorySelectTarget.value
    }

    if (this.hasMinSliderTarget && this.hasMaxSliderTarget &&
        this.hasMinPriceInputTarget && this.hasMaxPriceInputTarget) {
      this.minPriceInputTarget.value = this.minSliderTarget.value
      this.maxPriceInputTarget.value = this.maxSliderTarget.value
    }

    closeModal('filter_modal')
    updateURL(this.searchFormTarget, () => this.searchFormTarget.requestSubmit())
  }

  resetFilters() {
    const searchInput = this.searchFormTarget.querySelector('input[name="search"]')
    if (searchInput) {
      searchInput.value = ''
    }

    if (this.hasModalCategorySelectTarget) {
      this.modalCategorySelectTarget.value = ''
    }

    if (this.hasCategoryInputTarget) {
      this.categoryInputTarget.value = ''
    }

    if (this.hasMinPriceInputTarget) {
      this.minPriceInputTarget.value = ''
    }

    if (this.hasMaxPriceInputTarget) {
      this.maxPriceInputTarget.value = ''
    }

    if (this.hasMinSliderTarget) {
      this.minSliderTarget.value = 0
    }

    if (this.hasMaxSliderTarget) {
      this.maxSliderTarget.value = 1000000
    }

    if (this.hasSortSelectTarget) {
      this.sortSelectTarget.value = 'newest'
    }

    const sortByInput = this.searchFormTarget.querySelector('input[name="sort_by"]')
    if (sortByInput) {
      sortByInput.remove()
    }

    if (this.hasPerPageSelectTarget) {
      this.perPageSelectTarget.value = '12'
    }

    if (this.hasSearchInputTarget) this.searchInputTarget.value = ''
    if (this.hasModalCategorySelectTarget) this.modalCategorySelectTarget.value = ''
    if (this.hasCategoryInputTarget) this.categoryInputTarget.value = ''
    if (this.hasMinPriceInputTarget) this.minPriceInputTarget.value = ''
    if (this.hasMaxPriceInputTarget) this.maxPriceInputTarget.value = ''
    if (this.hasMinSliderTarget) this.minSliderTarget.value = 0
    if (this.hasMaxSliderTarget) this.maxSliderTarget.value = 1000000
    if (this.hasSortSelectTarget) this.sortSelectTarget.value = 'newest'
    if (this.hasSortByInputTarget) this.sortByInputTarget.value = ''

    closeModal('filter_modal')
    this.updateSliderValues()
    clearURLAndSubmit(() => this.searchFormTarget.requestSubmit())
  }

  toggleFilterModal() {
    openModal('filter_modal')
  }

  clearSearch() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
      updateURL(this.searchFormTarget, () => this.searchFormTarget.requestSubmit())
    }
  }

  clearCategoryFilter() {
    if (this.hasCategoryInputTarget) {
      this.categoryInputTarget.value = ''
      updateURL(this.searchFormTarget, () => this.searchFormTarget.requestSubmit())
    }
  }

  clearPriceFilter() {
    if (this.hasMinPriceInputTarget && this.hasMaxPriceInputTarget) {
      this.minPriceInputTarget.value = ''
      this.maxPriceInputTarget.value = ''
      updateURL(this.searchFormTarget, () => this.searchFormTarget.requestSubmit())
    }
  }

  clearSortFilter() {
    if (this.hasSortSelectTarget && this.hasSortByInputTarget) {
      this.sortSelectTarget.value = 'newest'
      this.sortByInputTarget.value = ''
      updateURL(this.searchFormTarget, () => this.searchFormTarget.requestSubmit())
    }
  }
}
