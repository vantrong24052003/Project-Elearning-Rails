import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chapter", "lesson", "video", "progress", "progressText"]

  connect() {
    this.updateProgress()
    this.highlightCurrentVideo()
  }

  toggleChapter(event) {
    const chapter = event.target.closest('[data-dashboard--course-viewer-target="chapter"]')
    const lessons = chapter.querySelectorAll('[data-dashboard--course-viewer-target="lesson"]')

    if (event.target.checked) {
      lessons.forEach(lesson => {
        lesson.classList.add('border-blue-200', 'dark:border-purple-700/30', 'shadow-sm')
      })
    } else {
      lessons.forEach(lesson => {
        lesson.classList.remove('border-blue-200', 'dark:border-purple-700/30', 'shadow-sm')
      })
    }
  }

  toggleLesson(event) {
    const lesson = event.target.closest('[data-dashboard--course-viewer-target="lesson"]')
    const videos = lesson.querySelectorAll('[data-dashboard--course-viewer-target="video"]')

    if (event.target.checked) {
      videos.forEach(video => {
        video.classList.add('bg-blue-50', 'dark:bg-purple-900/40', 'text-blue-700', 'dark:text-white', 'shadow-sm')
      })
    } else {
      videos.forEach(video => {
        video.classList.remove('bg-blue-50', 'dark:bg-purple-900/40', 'text-blue-700', 'dark:text-white', 'shadow-sm')
      })
    }
  }

  markVideoActive(event) {
    this.videoTargets.forEach(video => {
      video.classList.remove('bg-blue-50', 'dark:bg-purple-900/40', 'text-blue-700', 'dark:text-white', 'shadow-sm')
    })

    const video = event.currentTarget
    video.classList.add('bg-blue-50', 'dark:bg-purple-900/40', 'text-blue-700', 'dark:text-white', 'shadow-sm')

    this.updateProgress()
  }

  updateProgress() {
    const totalVideos = this.videoTargets.length
    const completedVideos = this.videoTargets.filter(video =>
      video.classList.contains('bg-blue-50') || video.classList.contains('dark:bg-purple-900/40')
    ).length

    const progress = (completedVideos / totalVideos) * 100
    this.progressTarget.style.width = `${progress}%`
    this.progressTextTarget.textContent = `${completedVideos} / ${totalVideos}`
  }

  highlightCurrentVideo() {
    const currentVideo = this.videoTargets.find(video =>
      video.classList.contains('bg-blue-50') || video.classList.contains('dark:bg-purple-900/40')
    )

    if (currentVideo) {
      const lesson = currentVideo.closest('[data-dashboard--course-viewer-target="lesson"]')
      const chapter = lesson.closest('[data-dashboard--course-viewer-target="chapter"]')

      chapter.querySelector('input[type="checkbox"]').checked = true
      lesson.querySelector('input[type="checkbox"]').checked = true

      chapter.classList.add('bg-blue-50/50', 'dark:bg-gray-700/20', 'border-blue-300', 'dark:border-purple-500/30', 'shadow-md')
      lesson.classList.add('border-blue-200', 'dark:border-purple-700/30', 'shadow-sm')
    }
  }
}
