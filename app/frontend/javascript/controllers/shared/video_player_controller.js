import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["player", "qualityInfo"]

  connect() {
    console.log("VideoPlayer controller kết nối")
    if (this.hasPlayerTarget) {
      setTimeout(() => this.initializePlayer(), 100)
    }
  }

  disconnect() {
    console.log("VideoPlayer controller ngắt kết nối")
    if (this.hls) {
      this.hls.destroy()
    }
    if (this.debugInterval) {
      clearInterval(this.debugInterval)
    }
  }

  initializePlayer() {
    const video = this.playerTarget

    const videoSource = video.querySelector('source')
    if (!videoSource) {
      console.error("Không tìm thấy source element trong video")
      return
    }

    const videoSrc = videoSource.src

    if (!videoSrc) {
      console.error("Không tìm thấy nguồn video (src trống)")
      return
    }

    console.log("Nguồn video:", videoSrc)

    // HLS (m3u8) format
    if (videoSrc.includes('.m3u8')) {
      console.log("Đã phát hiện định dạng HLS (.m3u8)")
      this.setupHls(video, videoSrc)
    } else {
      console.log("Không phải định dạng HLS, sử dụng video player mặc định")
    }
  }

  setupHls(video, hlsUrl) {
    if (typeof Hls === 'undefined') {
      console.log("HLS.js chưa được tải, đang tải thư viện...")
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/hls.js@latest'
      script.async = true
      script.onload = () => {
        console.log("HLS.js đã được tải thành công")
        this._initHls(video, hlsUrl)
      }
      document.head.appendChild(script)
    } else {
      console.log("HLS.js đã được tải sẵn, khởi tạo player")
      this._initHls(video, hlsUrl)
    }
  }

  _initHls(video, hlsUrl) {
    if (!Hls.isSupported()) {
      console.error("Trình duyệt không hỗ trợ HLS.js")
      return
    }

    if (this.hls) {
      console.log("Hủy instance HLS hiện tại")
      this.hls.destroy()
    }

    console.log("Khởi tạo HLS.js với URL:", hlsUrl)

    this.hls = new Hls({
      enableWorker: true,
      startLevel: -1,
      debug: false,
      autoStartLoad: true,
      capLevelToPlayerSize: true,
      abrEwmaDefaultEstimate: 500000,
      abrEwmaFastLive: 3.0,
      abrEwmaFastVoD: 3.0,
      abrBandWidthFactor: 0.95,
      abrBandWidthUpFactor: 0.7,
      abrMaxWithRealBitrate: true,
    })

    this.hls.loadSource(hlsUrl)
    this.hls.attachMedia(video)

    this.hls.on(Hls.Events.MANIFEST_PARSED, (event, data) => {
      this.levels = data.levels

      data.levels.forEach((level, index) => {
        const height = level.height
        const width = level.width
        const bitrate = Math.round(level.bitrate / 1000)
        console.log(`Chất lượng ${index}: ${width}x${height}, ${bitrate} Kbps`)
      })

      const mainBadge = document.querySelector('.video-quality-badge')
      if (mainBadge && data.levels.length > 0) {
        const maxHeightLevel = data.levels.reduce((prev, current) =>
          (prev.height > current.height) ? prev : current
        )

        let qualityLabel = "HLS"
        if (maxHeightLevel.height >= 720) {
          qualityLabel = "HLS-720"
        } else if (maxHeightLevel.height >= 480) {
          qualityLabel = "HLS-480"
        } else if (maxHeightLevel.height >= 360) {
          qualityLabel = "HLS-360"
        }

        mainBadge.textContent = qualityLabel
      }

      video.play().catch(e => console.error("Không thể tự động phát video:", e))
    })

    this.hls.on(Hls.Events.LEVEL_SWITCHED, (event, data) => {
      const levelIndex = data.level

      if (this.levels && this.levels[levelIndex]) {
        const level = this.levels[levelIndex]
        const height = level.height
        const width = level.width
        const bitrate = Math.round(level.bitrate / 1000)

        let qualityLabel, badgeClass
        if (height >= 720) {
          qualityLabel = "HLS-720"
          badgeClass = "bg-green-500/80"
        } else if (height >= 480) {
          qualityLabel = "HLS-480"
          badgeClass = "bg-blue-500/80"
        } else if (height >= 360) {
          qualityLabel = "HLS-360"
          badgeClass = "bg-yellow-500/80"
        } else {
          qualityLabel = `HLS-${height}`
          badgeClass = "bg-gray-500/80"
        }

        console.log(`=== ĐANG PHÁT: ${qualityLabel} ===`)
        console.log(`Độ phân giải: ${width}x${height}, Bitrate: ${bitrate} Kbps`)

        if (this.hasQualityInfoTarget) {
          this.qualityInfoTarget.textContent = `${qualityLabel} - ${bitrate} Kbps`
          this.qualityInfoTarget.className = `absolute top-2 left-2 ${badgeClass} text-white text-xs px-2 py-1 rounded-lg z-10`
          this.qualityInfoTarget.classList.remove('hidden')

          clearTimeout(this.qualityInfoTimeout)
          this.qualityInfoTimeout = setTimeout(() => {
            this.qualityInfoTarget.classList.add('hidden')
          }, 3000)
        }

        const mainBadge = document.querySelector('.video-quality-badge')
        if (mainBadge) {
          mainBadge.textContent = qualityLabel

          mainBadge.className = `absolute top-2 right-2 ${badgeClass} text-white text-xs px-2 py-1 rounded-lg z-10 font-medium video-quality-badge`
        }
      }
    })

    this.hls.on(Hls.Events.ERROR, (event, data) => {
      console.error("Lỗi HLS:", data.type, data.details, data)

      if (data.fatal) {
        switch(data.type) {
          case Hls.ErrorTypes.NETWORK_ERROR:
            console.warn("Lỗi mạng, đang thử lại...", data)
            this.hls.startLoad()
            break
          case Hls.ErrorTypes.MEDIA_ERROR:
            console.warn("Lỗi media, đang thử khôi phục...", data)
            this.hls.recoverMediaError()
            break
          default:
            console.error("Lỗi HLS không khắc phục được:", data)
            break
        }
      }
    })

    this.hls.on(Hls.Events.FRAG_BUFFERED, (event, data) => {
      const bandwidth = Math.round(this.hls.bandwidthEstimate / 1000)
      console.log(`Băng thông hiện tại: ${bandwidth} Kbps`)
    })

    this.debugInterval = setInterval(() => {
      if (this.hls) {
        try {
          const currentLevel = this.hls.currentLevel
          const bandwidth = Math.round(this.hls.bandwidthEstimate / 1000)

          let qualityInfo = "Đang tải..."

          if (currentLevel >= 0 && this.levels && this.levels[currentLevel]) {
            const level = this.levels[currentLevel]
            const height = level.height
            const bitrate = Math.round(level.bitrate / 1000)

            if (height >= 720) {
              qualityInfo = `HLS-720 (${bitrate} Kbps)`
            } else if (height >= 480) {
              qualityInfo = `HLS-480 (${bitrate} Kbps)`
            } else if (height >= 360) {
              qualityInfo = `HLS-360 (${bitrate} Kbps)`
            } else {
              qualityInfo = `HLS-${height} (${bitrate} Kbps)`
            }
          }

          console.log(`Thống kê HLS: ${qualityInfo}, Băng thông: ${bandwidth} Kbps`)
        } catch (e) {
          console.error("Lỗi khi log trạng thái:", e)
        }
      }
    }, 10000)
  }
}
