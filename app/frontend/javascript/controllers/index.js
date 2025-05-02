import { application } from "./application"


import audio_player_controller from "./shared/audio_player_controller"
import header_controller from "./shared/header_controller"
import dropdown_controller from "./shared/dropdown_controller"
import faq_controller from "./home/faq_controller"
import hero_controller from "./home/hero_controller"
import clipboard_controller from "./shared/clipboard_controller"
import countdown_controller from "./shared/countdown_controller"
import course_filter_controller from "./dashboard/course_filter_controller"
import lazy_loading_controller from "./shared/lazy_loading_controller"
import course_viewer_controller from "./dashboard/course_viewer_controller"
import quiz_timer_controller from "./dashboard/quiz_timer_controller"
import quiz_index_controller from "./dashboard/quiz_index_controller"
import drawer_controller from "./shared/drawer_controller"

// home
application.register("home--faq", faq_controller)
application.register("home--hero", hero_controller)

// shared
application.register("shared--audio-player", audio_player_controller)
application.register("shared--header", header_controller)
application.register("shared--dropdown", dropdown_controller)
application.register("shared--lazy-loading", lazy_loading_controller)
application.register("shared--clipboard", clipboard_controller)
application.register("shared--countdown", countdown_controller)
application.register("shared--drawer", drawer_controller)

// dashboard
application.register("dashboard--course-filter", course_filter_controller)
application.register("dashboard--course-viewer", course_viewer_controller)
application.register("dashboard--quiz-timer", quiz_timer_controller)
application.register("dashboard--quiz-index", quiz_index_controller)

// manage
