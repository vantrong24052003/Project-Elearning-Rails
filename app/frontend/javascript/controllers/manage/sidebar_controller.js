import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "mainContent", "menuLabel"]

  connect() {
    console.log("Sidebar controller connected")

    this.applyNavLinkClasses()

    this.checkScreenSize()
    window.addEventListener('resize', this.checkScreenSize.bind(this))

    document.addEventListener('click', this.handleOutsideClick.bind(this))
  }

  disconnect() {
    window.removeEventListener('resize', this.checkScreenSize.bind(this))
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
  }

  applyNavLinkClasses() {
    const menuItems = this.sidebarTarget.querySelectorAll('.sidebar-menu a div')
    menuItems.forEach(item => {
      if (!item.classList.contains('nav-link')) {
        item.classList.add('nav-link')
      }
    })
  }

  checkScreenSize() {
    if (window.innerWidth <= 767) {
      this.sidebarTarget.classList.remove('show-mobile')
      this.mainContentTarget.classList.remove('expanded')
    } else {
      this.sidebarTarget.classList.remove('collapsed')
      this.mainContentTarget.classList.remove('expanded')
      this.showMenuLabels()
    }
  }

  toggle(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (window.innerWidth <= 767) {
      this.sidebarTarget.classList.toggle('show-mobile')
    } else {
      const isCollapsing = !this.sidebarTarget.classList.contains('collapsed')
      this.sidebarTarget.classList.toggle('collapsed')
      this.mainContentTarget.classList.toggle('expanded')
      if (isCollapsing) {
        this.hideMenuLabels()
      } else {
        this.showMenuLabels()
      }
    }
  }

  hideMenuLabels() {
    this.menuLabelTargets.forEach(label => {
      label.style.display = 'none'
    })
  }

  showMenuLabels() {
    this.menuLabelTargets.forEach(label => {
      label.style.display = ''
    })
  }

  handleOutsideClick(event) {
    if (window.innerWidth <= 767) {
      if (this.sidebarTarget.classList.contains('show-mobile') &&
          !this.sidebarTarget.contains(event.target) &&
          !event.target.closest('[data-action*="manage--sidebar#toggle"]')) {
        this.sidebarTarget.classList.remove('show-mobile')
      }
    }
  }
}
