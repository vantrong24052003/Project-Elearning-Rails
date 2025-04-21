import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "mainContent", "menuLabel"]

  connect() {
    console.log("Sidebar controller connected")
    
    // Apply correct classes to nav links
    this.applyNavLinkClasses()
    
    this.checkScreenSize()
    window.addEventListener('resize', this.checkScreenSize.bind(this))

    // Handle clicks outside the sidebar to close it on mobile
    document.addEventListener('click', this.handleOutsideClick.bind(this))
  }

  disconnect() {
    window.removeEventListener('resize', this.checkScreenSize.bind(this))
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
  }
  
  applyNavLinkClasses() {
    // Select all menu items and make sure they have the nav-link class
    const menuItems = this.sidebarTarget.querySelectorAll('.sidebar-menu a div')
    menuItems.forEach(item => {
      if (!item.classList.contains('nav-link')) {
        item.classList.add('nav-link')
      }
    })
  }

  checkScreenSize() {
    if (window.innerWidth <= 767) {
      // On mobile, we want the sidebar to be hidden initially
      this.sidebarTarget.classList.remove('show-mobile')
      this.mainContentTarget.classList.remove('expanded')
    } else {
      // On desktop, show the full sidebar by default
      this.sidebarTarget.classList.remove('collapsed')
      this.mainContentTarget.classList.remove('expanded')
      // Ensure menu labels are visible
      this.showMenuLabels()
    }
  }

  toggle(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (window.innerWidth <= 767) {
      // On mobile, show/hide the sidebar completely
      this.sidebarTarget.classList.toggle('show-mobile')
    } else {
      // On larger screens, toggle between expanded and collapsed
      const isCollapsing = !this.sidebarTarget.classList.contains('collapsed')
      this.sidebarTarget.classList.toggle('collapsed')
      this.mainContentTarget.classList.toggle('expanded')
      
      // Update menu labels visibility
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
    // Only apply this on mobile screens
    if (window.innerWidth <= 767) {
      // Check if the sidebar is visible and the click was outside of it
      if (this.sidebarTarget.classList.contains('show-mobile') &&
          !this.sidebarTarget.contains(event.target) &&
          !event.target.closest('[data-action*="manage--sidebar#toggle"]')) {
        this.sidebarTarget.classList.remove('show-mobile')
      }
    }
  }
}
