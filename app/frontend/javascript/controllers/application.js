import { Application } from "@hotwired/stimulus"
import toastr from "toastr"
import "toastr/build/toastr.min.css"
const application = Application.start()

application.debug = false
window.Stimulus   = application
window.toastr = toastr
export { application }
