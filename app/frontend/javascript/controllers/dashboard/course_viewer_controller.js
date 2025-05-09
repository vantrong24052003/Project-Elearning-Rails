import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chapter", "lesson", "video"]

  connect() {
    this.highlightActiveItems()
  }

  toggleChapter(event) {
    const chapterElement = event.currentTarget.closest('[data-dashboard--course-viewer-target="chapter"]')

    if (event.currentTarget.checked) {
      chapterElement.classList.add('active-chapter')
      chapterElement.style.borderColor = 'rgba(168, 85, 247, 0.3)'
    } else {
      chapterElement.classList.remove('active-chapter')
      chapterElement.style.borderColor = ''
    }
  }

  markVideoActive(event) {
    if (this.hasVideoTarget) {
      this.videoTargets.forEach(video => {
        video.classList.remove('bg-purple-900/40', 'text-white', 'font-medium')
        video.classList.add('text-gray-300')

        const icon = video.querySelector('svg')
        if (icon) {
          icon.classList.remove('text-purple-400')
          icon.classList.add('text-gray-400')
        }

        const badge = video.querySelector('.rounded-full')
        if (badge) {
          badge.classList.remove('text-purple-200')
          badge.classList.add('text-gray-400')
        }
      })
    }

    const currentVideo = event.currentTarget
    currentVideo.classList.add('bg-purple-900/40', 'text-white', 'font-medium')
    currentVideo.classList.remove('text-gray-300')

    const icon = currentVideo.querySelector('svg')
    if (icon) {
      icon.classList.add('text-purple-400')
      icon.classList.remove('text-gray-400')
    }

    const badge = currentVideo.querySelector('.rounded-full')
    if (badge) {
      badge.classList.add('text-purple-200')
      badge.classList.remove('text-gray-400')
    }

    this.openParentAccordions(currentVideo)
  }


  highlightActiveItems() {
    const url = new URL(window.location.href)
    const lessonId = url.searchParams.get('lesson_id')
    const videoId = url.searchParams.get('video_id')

    if (lessonId && this.hasLessonTarget) {
      const activeLesson = this.lessonTargets.find(lesson =>
        lesson.dataset.lessonId === lessonId
      )

    }

    if (videoId && this.hasVideoTarget) {
      const activeVideo = this.videoTargets.find(video =>
        video.dataset.videoId === videoId
      )

      if (activeVideo) {
        activeVideo.classList.add('bg-purple-900/40', 'text-white', 'font-medium')
        activeVideo.classList.remove('text-gray-300')

        const icon = activeVideo.querySelector('svg')
        if (icon) {
          icon.classList.add('text-purple-400')
          icon.classList.remove('text-gray-400')
        }

        const badge = activeVideo.querySelector('.rounded-full')
        if (badge) {
          badge.classList.add('text-purple-200')
          badge.classList.remove('text-gray-400')
        }

        this.openParentAccordions(activeVideo)
      }
    }

    if (!lessonId && !videoId && this.hasChapterTarget) {
      const firstChapter = this.chapterTargets[0]
      if (firstChapter) {
        const checkbox = firstChapter.querySelector('input[type="checkbox"]')
        if (checkbox) checkbox.checked = true
      }
    }
  }
}
