import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["player", "qualityButton", "qualitySelector", "qualityOption", "currentQuality", "qualityInfo"]

  connect() {
    this.levels = []
    this.hls = null
    this.setupVideoPlayer()
  }

  disconnect() {
    if (this.hls) {
      this.hls.destroy()
    }
  }

  toggleQualitySelector(event) {
    event.preventDefault()
    event.stopPropagation()

    this.qualitySelectorTarget.classList.toggle('hidden')
  }

  selectQuality(event) {
    event.preventDefault()
    event.stopPropagation()

    if (!this.hls) return

    const quality = event.currentTarget.dataset.quality

    if (quality === 'auto') {
      this.hls.currentLevel = -1
      this.currentQualityTarget.textContent = 'Tự động'
      console.log("Đã chuyển sang chế độ chất lượng tự động")
    } else {
      let selectedLevel = -1
      const targetHeight = parseInt(quality.replace('p', ''))

      for (let i = 0; i < this.levels.length; i++) {
        if (this.levels[i].height === targetHeight) {
          selectedLevel = i
          break
        }
      }

      if (selectedLevel === -1) {
        let closestMatch = { level: -1, diff: 1000 }
        for (let i = 0; i < this.levels.length; i++) {
          const diff = Math.abs(this.levels[i].height - targetHeight)
          if (diff < closestMatch.diff) {
            closestMatch = { level: i, diff: diff }
          }
        }
        if (closestMatch.level >= 0) {
          selectedLevel = closestMatch.level
        }
      }

      if (selectedLevel !== -1) {
        this.hls.currentLevel = selectedLevel
        this.currentQualityTarget.textContent = quality
        console.log(`Đã chuyển sang chất lượng: ${quality} (Level: ${selectedLevel})`)
      } else {
        this.hls.currentLevel = -1
        this.currentQualityTarget.textContent = 'Tự động'
      }
    }

    this.qualitySelectorTarget.classList.add('hidden')
  }

  setupVideoPlayer() {
    const video = this.playerTarget
    const qualityButton = this.hasQualityButtonTarget ? this.qualityButtonTarget : null
    const hlsUrl = video.querySelector('source')?.src

    document.addEventListener('click', (event) => {
      if (this.hasQualitySelectorTarget &&
          !this.qualitySelectorTarget.contains(event.target) &&
          !this.qualityButtonTarget?.contains(event.target)) {
        this.qualitySelectorTarget.classList.add('hidden')
      }
    })

    if (hlsUrl && hlsUrl.includes('.m3u8') && typeof Hls !== 'undefined') {
      if (Hls.isSupported()) {
        this.setupHls(video, hlsUrl)
      }
      else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = hlsUrl

        if (qualityButton) {
          qualityButton.classList.remove('hidden')
          qualityButton.addEventListener('click', () => {
            alert('Trình duyệt của bạn tự động điều chỉnh chất lượng video.')
          })
        }
      }
    }
  }

  setupHls(video, hlsUrl) {
    this.hls = new Hls({
      maxBufferLength: 30,  // Buffer tối đa 30 giây video
      maxMaxBufferLength: 60,
      enableWorker: true,
      lowLatencyMode: false,
      startLevel: -1, // Auto quality
      debug: true     // Bật debug để log nhiều thông tin hơn
    })


    this.hls.on(Hls.Events.MANIFEST_PARSED, (event, data) => {
      this.levels = data.levels

      this.levels.forEach((level, index) => {
        console.log(`Chất lượng ${index}: ${level.width}x${level.height}, bitrate: ${(level.bitrate/1000000).toFixed(2)}Mbps`)
      })

      if (this.levels.length > 1 && this.hasQualityButtonTarget) {
        this.qualityButtonTarget.classList.remove('hidden')
      }
    })

    this.hls.on(Hls.Events.LEVEL_SWITCHED, (event, data) => {
      const level = data.level

      if (this.hasCurrentQualityTarget) {
        if (this.hls.autoLevelEnabled) {
          this.currentQualityTarget.textContent = 'Tự động'
          console.log('Chế độ chất lượng: Tự động')
        } else if (this.levels[level]) {
          const height = this.levels[level].height
          if (height >= 720) {
            this.currentQualityTarget.textContent = 'HD (720p)'
          } else if (height >= 480) {
            this.currentQualityTarget.textContent = 'SD (480p)'
          } else if (height >= 360) {
            this.currentQualityTarget.textContent = 'Thấp (360p)'
          } else {
            this.currentQualityTarget.textContent = `${height}p`
          }
        }
      }
    })

    this.hls.loadSource(hlsUrl)
    this.hls.attachMedia(video)
  }
}
