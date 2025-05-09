import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    videoId: String,
    hlsUrl: String,
    mp4Url: String,
    courseId: String
  }

  connect() {
    this.setupPlayer()
    this.setupProgressTracking()
  }

  setupPlayer() {
    const video = this.element

    if (this.hasHlsUrlValue && this.hlsUrlValue) {
      this.initializeHlsPlayer(video, this.hlsUrlValue)
    }

    video.addEventListener('ended', this.markVideoAsCompleted.bind(this))

    this.progressInterval = setInterval(() => {
      this.saveProgress(video.currentTime)
    }, 5000)
  }

  initializeHlsPlayer(video, hlsUrl) {
    if (!window.Hls) return

    if (Hls.isSupported()) {
      const hls = new Hls({
        enableWorker: true,
        maxBufferLength: 30,
        maxMaxBufferLength: 60,
        maxBufferSize: 60 * 1000 * 1000,
        maxBufferHole: 0.5,
        lowLatencyMode: false,
        startFragPrefetch: false,
        progressive: true
      })

      hls.on(Hls.Events.ERROR, (event, data) => {
        if (data.fatal) {
          switch(data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              hls.startLoad()
              break
            case Hls.ErrorTypes.MEDIA_ERROR:
              hls.recoverMediaError()
              break
            default:
              video.src = this.mp4UrlValue
              break
          }
        }
      })

      hls.loadSource(hlsUrl)
      hls.attachMedia(video)

      this.hls = hls
    }
    else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = hlsUrl
    }
    else if (this.hasMp4UrlValue && this.mp4UrlValue) {
      video.src = this.mp4UrlValue
    }
  }

  setupProgressTracking() {
    this.loadSavedProgress()
  }

  loadSavedProgress() {
    const savedProgress = localStorage.getItem(`video_progress_${this.videoIdValue}`)
    if (savedProgress) {
      const progress = JSON.parse(savedProgress)
      if (progress.time > 0) {
        this.element.currentTime = progress.time
      }
    }
  }

  saveProgress(currentTime) {
    if (!currentTime || currentTime <= 0) return

    localStorage.setItem(`video_progress_${this.videoIdValue}`, JSON.stringify({
      time: currentTime,
      updatedAt: new Date().toISOString()
    }))

    const lastServerSync = this.lastServerSync || 0
    if (Date.now() - lastServerSync > 30000) {
      this.syncProgressWithServer(currentTime)
      this.lastServerSync = Date.now()
    }
  }

  syncProgressWithServer(currentTime) {
    if (currentTime < 5) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrfToken) return

    fetch('/api/video_progresses', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({
        video_id: this.videoIdValue,
        current_time: currentTime,
        duration: this.element.duration,
        course_id: this.courseIdValue
      })
    })
  }


  disconnect() {
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
    }

    if (this.hls) {
      this.hls.destroy()
    }
  }
}
