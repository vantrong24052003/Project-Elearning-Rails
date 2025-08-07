import "@hotwired/turbo-rails"
import "./controllers"
import "toastr/build/toastr.min.css"
import toastr from "toastr"

import { createIcons, icons } from "lucide"
import "hls.js"
import "chartkick/chart.js"

toastr.options = {
  closeButton: true,
  progressBar: true,
  positionClass: "toast-top-right",
  timeOut: "5000",
  extendedTimeOut: "1000",
  preventDuplicates: true,
  newestOnTop: true
}

document.addEventListener("DOMContentLoaded", () => {
  createIcons({ icons })
})

document.addEventListener("turbo:load", () => {
  createIcons({ icons })
})

document.addEventListener("turbo:before-cache", () => {
  toastr.clear()
  toastr.remove()
})

window.addEventListener('pageshow', (event) => {
  if (event.persisted) {
    toastr.clear()
    toastr.remove()
  }
})
