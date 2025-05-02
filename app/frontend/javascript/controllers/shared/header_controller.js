import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "lightIcon", "darkIcon", "userMenu"]

  connect() {
    this.updateThemeIcons()
  }

  toggleTheme() {
    if (document.documentElement.classList.contains('dark')) {
      document.documentElement.classList.remove('dark')
      document.documentElement.setAttribute('data-theme', 'light')
      localStorage.setItem('theme-mode', 'light')
    } else {
      document.documentElement.classList.add('dark')
      document.documentElement.setAttribute('data-theme', 'dark')
      localStorage.setItem('theme-mode', 'dark')
    }

    this.updateThemeIcons()
  }

  updateThemeIcons() {
    const isDarkMode = document.documentElement.classList.contains('dark')

    this.lightIconTargets.forEach(icon => {
      icon.classList.toggle('hidden', isDarkMode)
    })

    this.darkIconTargets.forEach(icon => {
      icon.classList.toggle('hidden', !isDarkMode)
    })
  }

  toggleMobileMenu(event) {
    this.mobileMenuTarget.classList.toggle('hidden')
  }

  scrollToSection(event) {
    const sectionId = event.params.section
    const element = document.getElementById(sectionId)
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' })
    }
  }

  scrollToSectionAndCloseMobileMenu(event) {
    this.scrollToSection(event)
    if (this.hasMobileMenuTarget) {
      this.mobileMenuTarget.classList.add('hidden')
    }
  }
}
