import { Application } from "@hotwired/stimulus"
import toastr from "toastr"
import "toastr/build/toastr.min.css"
const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application
window.toastr = toastr
export { application }
