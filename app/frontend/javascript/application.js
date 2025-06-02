import "@hotwired/turbo-rails"
import "./controllers"
import "toastr/build/toastr.min.css";
import { createIcons, icons } from "lucide"
import "hls.js"
import "chartkick/chart.js"

toastr.options = {
  closeButton: true,
  progressBar: true,
  positionClass: "toast-top-right",
  timeOut: "5000",
};

document.addEventListener("DOMContentLoaded", () => {
  createIcons({ icons })
})

document.addEventListener("turbo:load", () => {
  createIcons({ icons })
})
