import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["mobileMenu", "menuOpenIcon", "menuCloseIcon", "userMenu", "themeToggleLightIcon", "themeToggleDarkIcon"];

  connect() {
    this.applyStoredTheme()
  }

  toggleTheme() {
    if (document.documentElement.classList.contains('dark')) {
      document.documentElement.classList.remove('dark')
      localStorage.setItem('color-theme', 'light')
      document.getElementById('theme-toggle-dark-icon').classList.add('hidden')
      document.getElementById('theme-toggle-light-icon').classList.remove('hidden')
    } else {
      document.documentElement.classList.add('dark')
      localStorage.setItem('color-theme', 'dark')
      document.getElementById('theme-toggle-light-icon').classList.add('hidden')
      document.getElementById('theme-toggle-dark-icon').classList.remove('hidden')
    }
  }

  applyStoredTheme() {
    const storedTheme = localStorage.getItem('color-theme')
    const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    const isDarkMode = storedTheme === 'dark' || (!storedTheme && darkModeMediaQuery.matches)

    if (isDarkMode) {
      document.documentElement.classList.add('dark')
      document.getElementById('theme-toggle-dark-icon').classList.remove('hidden')
      document.getElementById('theme-toggle-light-icon').classList.add('hidden')
    } else {
      document.documentElement.classList.remove('dark')
      document.getElementById('theme-toggle-dark-icon').classList.add('hidden')
      document.getElementById('theme-toggle-light-icon').classList.remove('hidden')
    }
  }

  toggleMobileMenu(event) {
    this.mobileMenuTarget.classList.toggle('hidden')

    // Update aria-expanded attribute
    const expanded = !this.mobileMenuTarget.classList.contains('hidden')
    event.currentTarget.setAttribute('aria-expanded', expanded)
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
    this.mobileMenuTarget.classList.add('hidden')

    // Find the mobile menu button and update its aria-expanded attribute
    const mobileMenuButton = document.querySelector('[aria-controls="mobile-menu"]')
    if (mobileMenuButton) {
      mobileMenuButton.setAttribute('aria-expanded', 'false')
    }
  }
}
