import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "searchForm", "categoryInput", "minPriceInput", "maxPriceInput",
    "categorySelect", "sortSelect", "modalCategorySelect", "modalPriceMin", "modalPriceMax",
    "minSlider", "maxSlider", "range"
  ]

  connect() {
    console.log("Course filter controller connected")
    this.initializePriceSliders()
  }

  submitForm(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.hasMinPriceInputTarget && this.hasMaxPriceInputTarget) {
      const minPrice = this.minPriceInputTarget.value;
      const maxPrice = this.maxPriceInputTarget.value;

      const url = new URL(window.location.href);
      const params = url.searchParams;

      if (minPrice) {
        params.set('min_price', minPrice);
      } else {
        params.delete('min_price');
      }

      if (maxPrice) {
        params.set('max_price', maxPrice);
      } else {
        params.delete('max_price');
      }

      window.history.pushState({}, '', url.toString());
    }

    this.searchFormTarget.requestSubmit()
  }

  filterChange() {
    this.submitForm()
  }

  toggleFilterModal() {
    const modal = document.getElementById('filter_modal')
    if (modal) {
      modal.showModal ? modal.showModal() : modal.close()
    }
  }

  initializePriceSliders() {
    if (this.hasMinSliderTarget && this.hasMaxSliderTarget) {
      const urlParams = new URLSearchParams(window.location.search);
      const minPrice = urlParams.get('min_price') || 0;
      const maxPrice = urlParams.get('max_price') || 1000000;

      this.minSliderTarget.value = minPrice;
      this.maxSliderTarget.value = maxPrice;

      this.updateSliderValues();
      this.updateSliderRangeUI();
    }
  }

  updateSliderValues() {
    if (!this.hasMinSliderTarget || !this.hasMaxSliderTarget) return

    const minValue = parseInt(this.minSliderTarget.value)
    const maxValue = parseInt(this.maxSliderTarget.value)

    if (minValue >= maxValue) {
      if (this.isDraggingMin) {
        this.minSliderTarget.value = maxValue - 50000
      } else {
        this.maxSliderTarget.value = minValue + 50000
      }
    }

    // Cập nhật các hiển thị giá trị
    if (this.hasModalPriceMinTarget) {
      this.modalPriceMinTarget.textContent = this.formatPrice(this.minSliderTarget.value)
    }

    if (this.hasModalPriceMaxTarget) {
      this.modalPriceMaxTarget.textContent = this.formatPrice(this.maxSliderTarget.value)
    }

    // Cập nhật thanh range UI
    this.updateSliderRangeUI()
  }

  updateSliderRangeUI() {
    if (!this.hasRangeTarget || !this.hasMinSliderTarget || !this.hasMaxSliderTarget) return

    const min = parseInt(this.minSliderTarget.value)
    const max = parseInt(this.maxSliderTarget.value)
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

  formatPrice(value) {
    return new Intl.NumberFormat('vi-VN').format(value)
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

    this.submitForm()
  }

  resetFilters() {
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

    this.updateSliderValues()

    const modal = document.getElementById('filter_modal')
    if (modal) {
      modal.close()
    }

    const url = new URL(window.location.href);
    url.searchParams.delete('min_price');
    url.searchParams.delete('max_price');
    window.history.pushState({}, '', url.toString());

    this.submitForm()
  }

  updateCategoryFilter(event) {
    if (this.hasCategoryInputTarget) {
      this.categoryInputTarget.value = event.target.value
      this.submitForm()
    }
  }

  applySortFilter() {
    if (this.hasSortSelectTarget) {
      const sortByInput = this.searchFormTarget.querySelector('input[name="sort_by"]')
      if (sortByInput) {
        sortByInput.value = this.sortSelectTarget.value
      }
      this.submitForm()
    }
  }

  searchWithDebounce() {
    if (this._searchTimeout) {
      clearTimeout(this._searchTimeout)
    }

    this._searchTimeout = setTimeout(() => {
      this.submitForm()
    }, 400)
  }
}
