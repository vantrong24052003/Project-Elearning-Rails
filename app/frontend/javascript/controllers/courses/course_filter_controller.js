import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchForm", "searchInput", "categoryInput", "categorySelect", "modalCategorySelect",
    "minPriceInput", "maxPriceInput", "filterModal", "sortSelect",
    "searchFilter", "categoryFilter", "priceFilter", "sortFilter",
    "searchTerm", "categoryName", "priceFilterText", "sortText",
    "priceMin", "priceMax", "modalPriceMin", "modalPriceMax", "activeFilters"
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
      const currentSortBy = this.sortSelectTarget.value
      const formData = new FormData(this.searchFormTarget)
      formData.set('sort_by', currentSortBy)

      const url = new URL(this.searchFormTarget.action)
      const params = new URLSearchParams([...formData.entries()])
      url.search = params.toString()

      Turbo.visit(url.toString(), {
        frame: "course-results",
        action: "replace"
      })
    }, 400)
  }

  updateCategoryFilter() {
    const categoryId = this.categorySelectTarget.value
    this.categoryInputTarget.value = categoryId

    const currentSortBy = this.sortSelectTarget.value
    const formData = new FormData(this.searchFormTarget)
    formData.set('sort_by', currentSortBy)

    const url = new URL(this.searchFormTarget.action)
    const params = new URLSearchParams([...formData.entries()])
    url.search = params.toString()

    Turbo.visit(url.toString(), {
      frame: "course-results",
      action: "replace"
    })
  }

  applySortFilter() {
    const sortValue = this.sortSelectTarget.value
    const formData = new FormData(this.searchFormTarget)
    formData.set('sort_by', sortValue)

    const url = new URL(this.searchFormTarget.action)
    const params = new URLSearchParams([...formData.entries()])
    url.search = params.toString()

    Turbo.visit(url.toString(), {
      frame: "course-results",
      action: "replace"
    })
  }

  clearSortFilter() {
    const formData = new FormData(this.searchFormTarget)
    formData.delete('sort_by')

    this.sortSelectTarget.value = "newest"

    const url = new URL(this.searchFormTarget.action)
    const params = new URLSearchParams([...formData.entries()])
    url.search = params.toString()

    Turbo.visit(url.toString(), {
      frame: "course-results",
      action: "replace"
    })
  }

  updatePriceRange(event) {
    this.minPriceInputTarget.value = event.detail.min
    this.maxPriceInputTarget.value = event.detail.max
    this.priceMinTarget.textContent = this.formatPrice(event.detail.min)
    this.priceMaxTarget.textContent = this.formatPrice(event.detail.max)
  }

  updateModalPriceRange(event) {
    this.modalPriceMinTarget.textContent = this.formatPrice(event.detail.min)
    this.modalPriceMaxTarget.textContent = this.formatPrice(event.detail.max)
  }

  formatPrice(price) {
    return new Intl.NumberFormat('vi-VN').format(price)
  }

  clearSearch() {
    this.searchInputTarget.value = ""

    const currentSortBy = this.sortSelectTarget.value
    const formData = new FormData(this.searchFormTarget)
    formData.delete('search')
    formData.set('sort_by', currentSortBy)

    const url = new URL(this.searchFormTarget.action)
    const params = new URLSearchParams([...formData.entries()])
    url.search = params.toString()

    Turbo.visit(url.toString(), {
      frame: "course-results",
      action: "replace"
    })
  }

  clearCategoryFilter() {
    this.categoryInputTarget.value = ""
    this.categorySelectTarget.value = ""
    if (this.hasModalCategorySelectTarget) {
      this.modalCategorySelectTarget.value = ""
    }

    const currentSortBy = this.sortSelectTarget.value
    const formData = new FormData(this.searchFormTarget)
    formData.delete('category_id')
    formData.set('sort_by', currentSortBy)

    const url = new URL(this.searchFormTarget.action)
    const params = new URLSearchParams([...formData.entries()])
    url.search = params.toString()

    Turbo.visit(url.toString(), {
      frame: "course-results",
      action: "replace"
    })
  }

  clearPriceFilter() {
    this.minPriceInputTarget.value = ""
    this.maxPriceInputTarget.value = ""

    const currentSortBy = this.sortSelectTarget.value
    const formData = new FormData(this.searchFormTarget)
    formData.delete('min_price')
    formData.delete('max_price')
    formData.set('sort_by', currentSortBy)

    const url = new URL(this.searchFormTarget.action)
    const params = new URLSearchParams([...formData.entries()])
    url.search = params.toString()

    Turbo.visit(url.toString(), {
      frame: "course-results",
      action: "replace"
    })
  }

  applyFilters() {
    const formData = new FormData(this.searchFormTarget)
    const url = new URL(this.searchFormTarget.action)
    const params = new URLSearchParams([...formData.entries()])
    url.search = params.toString()

    Turbo.visit(url.toString(), {
      frame: "course-results",
      action: "replace"
    })
    this.toggleFilterModal()
  }

  applyModalFilters() {
    if (this.hasModalCategorySelectTarget) {
      this.categoryInputTarget.value = this.modalCategorySelectTarget.value
    }

    if (this.hasModalPriceMinTarget && this.hasModalPriceMaxTarget) {
      const minPrice = this.modalPriceMinTarget.textContent.replace(/[^\d]/g, '')
      const maxPrice = this.modalPriceMaxTarget.textContent.replace(/[^\d]/g, '')

      this.minPriceInputTarget.value = minPrice
      this.maxPriceInputTarget.value = maxPrice
    }

    const currentSortBy = this.sortSelectTarget.value
    const formData = new FormData(this.searchFormTarget)
    formData.set('sort_by', currentSortBy)

    const url = new URL(this.searchFormTarget.action)
    const params = new URLSearchParams([...formData.entries()])
    url.search = params.toString()

    Turbo.visit(url.toString(), {
      frame: "course-results",
      action: "replace"
    })
    this.toggleFilterModal()
  }

  resetFilters() {
    this.searchInputTarget.value = ""
    this.categoryInputTarget.value = ""
    this.minPriceInputTarget.value = ""
    this.maxPriceInputTarget.value = ""
    this.categorySelectTarget.value = ""

    if (this.hasSortSelectTarget) {
      this.sortSelectTarget.value = "newest"
    }

    if (this.hasModalCategorySelectTarget) {
      this.modalCategorySelectTarget.value = ""
    }

    const url = new URL(this.searchFormTarget.action)

    Turbo.visit(url.toString(), {
      frame: "course-results",
      action: "replace"
    })

    if (!this.filterModalTarget.classList.contains("hidden")) {
      this.toggleFilterModal()
    }
  }
}
