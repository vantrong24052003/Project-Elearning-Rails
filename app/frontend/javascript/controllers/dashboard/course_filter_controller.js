import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchForm", "searchInput", "categoryInput", "minPriceInput", "maxPriceInput",
    "categorySelect", "sortSelect", "minSlider", "maxSlider", "range",
    "modalCategorySelect", "modalPriceMin", "modalPriceMax", "filterForm", "perPageSelect"
  ]

  connect() {
    console.log("Course filter controller connected")
    this.updateSliderValues()
  }

  searchWithDebounce() {
    if (this._searchTimeout) {
      clearTimeout(this._searchTimeout)
    }

    this._searchTimeout = setTimeout(() => {
      this.updateURL()
      this.submitForm()
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
    this.updateURL()
    this.submitForm()
  }

  applySortFilter() {
    if (this.hasSortSelectTarget) {
      const selectedValue = this.sortSelectTarget.value
      let sortByInput = this.searchFormTarget.querySelector('input[name="sort_by"]')

      if (!sortByInput) {
        sortByInput = document.createElement('input')
        sortByInput.type = 'hidden'
        sortByInput.name = 'sort_by'
        this.searchFormTarget.appendChild(sortByInput)
      }
      sortByInput.value = selectedValue
    }

    this.updateURL()
    this.submitForm()
  }

  updateSliderValues() {
    if (!this.hasMinSliderTarget || !this.hasMaxSliderTarget) return

    let minValue = parseInt(this.minSliderTarget.value)
    let maxValue = parseInt(this.maxSliderTarget.value)

    if (minValue >= maxValue) {
      if (this.isDraggingMin) {
        minValue = maxValue - 50000
        this.minSliderTarget.value = minValue
      } else {
        maxValue = minValue + 50000
        this.maxSliderTarget.value = maxValue
      }
    }

    if (this.hasModalPriceMinTarget) {
      this.modalPriceMinTarget.textContent = this.formatPrice(minValue)
    }

    if (this.hasModalPriceMaxTarget) {
      this.modalPriceMaxTarget.textContent = this.formatPrice(maxValue)
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

  trackDraggingMin() {
    this.isDraggingMin = true
    this.isDraggingMax = false
  }

  trackDraggingMax() {
    this.isDraggingMin = false
    this.isDraggingMax = true
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

    const modal = document.getElementById('filter_modal')
    if (modal) {
      modal.close()
    }

    this.updateURL()
    this.submitForm()
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

    this.updateSliderValues()

    const modal = document.getElementById('filter_modal')
    if (modal) {
      modal.close()
    }

    this.clearURLAndSubmit()
  }

  toggleFilterModal() {
    const modal = document.getElementById('filter_modal')
    if (modal) {
      modal.showModal ? modal.showModal() : modal.close()
    }
  }

  clearSearch() {
    const searchInput = this.searchFormTarget.querySelector('input[name="search"]')
    if (searchInput) {
      searchInput.value = ''
      this.updateURL()
      this.submitForm()
    }
  }

  clearCategoryFilter() {
    if (this.hasCategoryInputTarget) {
      this.categoryInputTarget.value = ''
      this.updateURL()
      this.submitForm()
    }
  }

  clearPriceFilter() {
    if (this.hasMinPriceInputTarget && this.hasMaxPriceInputTarget) {
      this.minPriceInputTarget.value = ''
      this.maxPriceInputTarget.value = ''
      this.updateURL()
      this.submitForm()
    }
  }

  clearSortFilter() {
    if (this.hasSortSelectTarget) {
      this.sortSelectTarget.value = 'newest'

      const sortByInput = this.searchFormTarget.querySelector('input[name="sort_by"]')
      if (sortByInput) {
        sortByInput.remove()
      }

      this.updateURL()
      this.submitForm()
    }
  }

  updateURL() {
    const formData = new FormData(this.searchFormTarget)
    const url = new URL(window.location.href)
    const params = url.searchParams

    // Clear all existing params except authenticity_token
    Array.from(params.keys()).forEach(key => {
      if (key !== 'authenticity_token') {
        params.delete(key)
      }
    })

    // Add only non-empty form values
    for (const [key, value] of formData.entries()) {
      if (key !== 'authenticity_token' && value && value.trim() !== '') {
        params.set(key, value)
      }
    }

    window.history.pushState({}, '', url.toString())
  }

  clearURLAndSubmit() {
    const url = new URL(window.location.href)
    const params = url.searchParams
    
    // Clear all params except authenticity_token
    Array.from(params.keys()).forEach(key => {
      if (key !== 'authenticity_token') {
        params.delete(key)
      }
    })

    window.history.pushState({}, '', url.toString())
    this.submitForm()
  }

  submitForm(event) {
    if (event) {
      event.preventDefault()
    }

    this.searchFormTarget.requestSubmit()
  }

  changePerPage() {
    this.updateURL()
    this.submitForm()
  }

  formatPrice(value) {
    return new Intl.NumberFormat('vi-VN').format(value)
  }
}
