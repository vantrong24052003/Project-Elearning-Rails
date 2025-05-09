import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "lightIcon", "darkIcon", "mobileToggleLight", "mobileToggleDark", "userMenu"]

  connect() {
    const savedTheme = localStorage.getItem('theme-mode')
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    const shouldBeDark = savedTheme === 'dark' || (savedTheme === null && prefersDark)

    if (shouldBeDark) {
      document.documentElement.classList.add('dark')
      document.documentElement.setAttribute('data-theme', 'dark')
    } else {
      document.documentElement.classList.remove('dark')
      document.documentElement.setAttribute('data-theme', 'light')
    }

    this.updateThemeIcons()

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
      if (localStorage.getItem('theme-mode') === null) {
        const newTheme = e.matches ? 'dark' : 'light'
        document.documentElement.classList.toggle('dark', e.matches)
        document.documentElement.setAttribute('data-theme', newTheme)
        this.updateThemeIcons()
      }
    })
  }

  toggleTheme() {
    const isDarkMode = document.documentElement.classList.contains('dark')
    const newTheme = isDarkMode ? 'light' : 'dark'

    document.documentElement.classList.toggle('dark', !isDarkMode)
    document.documentElement.setAttribute('data-theme', newTheme)
    localStorage.setItem('theme-mode', newTheme)

    this.updateThemeIcons()
  }

  updateThemeIcons() {
    const isDarkMode = document.documentElement.classList.contains('dark')

    if (this.hasLightIconTarget && this.hasDarkIconTarget) {
      this.lightIconTargets.forEach(icon => {
        icon.classList.toggle('hidden', !isDarkMode)
      })

      this.darkIconTargets.forEach(icon => {
        icon.classList.toggle('hidden', isDarkMode)
      })
    }

    if (this.hasMobileToggleLightTarget && this.hasMobileToggleDarkTarget) {
      this.mobileToggleLightTargets.forEach(icon => {
        icon.classList.toggle('bg-white', !isDarkMode)
        icon.classList.toggle('bg-transparent', isDarkMode)
      })

      this.mobileToggleDarkTargets.forEach(icon => {
        icon.classList.toggle('bg-gray-800', isDarkMode)
        icon.classList.toggle('bg-transparent', !isDarkMode)
      })
    }
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
