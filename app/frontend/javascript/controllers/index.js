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
import quiz_proctor_controller from "./dashboard/quiz_proctor_controller"
import quiz_index_controller from "./dashboard/quiz_index_controller"
import quiz_ip_detector_controller from "./dashboard/quiz_ip_detector_controller"
import quiz_cache_controller from "./dashboard/quiz_cache_controller"
import drawer_controller from "./shared/drawer_controller"
import ManageCoursesController from "./manage/courses_controller"
import VideoFilterController from "./manage/video_filter_controller"
import PaginationController from "./shared/pagination_controller"
import UploadFormController from "./manage/upload_form_controller"
import UploadTranscodingController from "./manage/upload_transcoding_controller"
import ManageUploadFormController from "./manage/upload_form_controller"
import VideoPlayerController from "./shared/video_player_controller"
import OverviewController from "./manage/overview_controller"
import toaster_controller from "./shared/toaster_controller"
import QuizFlagController from "./dashboard/quiz_flag_controller"
import QuizRedirectController from "./dashboard/quiz_redirect_controller"
import QuizTimerController from "./dashboard/quiz_timer_controller"
import course_content_select_controller from "./manage/course_content_select_controller"
import questions_controller from "./manage/questions_controller"
import questions_import_controller from "./manage/questions_import_controller"
import QuestionsPreviewController from "./manage/questions_preview_controller"
import QuizzesPreviewController from "./manage/quizzes_preview_controller"
import VideoAnalysisController from "./manage/video_analysis_controller"
import UsersController from "./manage/users_controller"
import EnrollmentsController from "./manage/enrollments_controller"
import QuizAttemptsController from "./manage/quiz_attempts_controller"
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
application.register("shared--pagination", PaginationController)
application.register("shared--video-player", VideoPlayerController)
application.register("shared--toaster", toaster_controller)

// dashboard
application.register("dashboard--course-filter", course_filter_controller)
application.register("dashboard--course-viewer", course_viewer_controller)
application.register("dashboard--quiz-timer", quiz_timer_controller)
application.register("dashboard--quiz-proctor", quiz_proctor_controller)
application.register("dashboard--quiz-index", quiz_index_controller)
application.register("dashboard--quiz-ip-detector", quiz_ip_detector_controller)
application.register("dashboard--video-player", VideoPlayerController)
application.register("dashboard--quiz-flag", QuizFlagController)
application.register("dashboard--quiz-redirect", QuizRedirectController)
application.register("dashboard--quiz-timer", QuizTimerController)
application.register("dashboard--quiz-cache", quiz_cache_controller)

// manage
application.register("manage--courses", ManageCoursesController)
application.register("manage--video-filter", VideoFilterController)
application.register("manage--upload-form", UploadFormController)
application.register("manage--upload-transcoding", UploadTranscodingController)
application.register("manage--upload-form", ManageUploadFormController)
application.register("manage--overview", OverviewController)
application.register("manage--course-content-select", course_content_select_controller)
application.register("manage--questions", questions_controller)
application.register("manage--questions-import", questions_import_controller)
application.register("manage--questions-preview", QuestionsPreviewController)
application.register("manage--quizzes-preview", QuizzesPreviewController)
application.register("manage--video-analysis", VideoAnalysisController)
application.register("manage--users", UsersController)
application.register("manage--enrollments", EnrollmentsController)
application.register("manage--quiz-attempts", QuizAttemptsController)
