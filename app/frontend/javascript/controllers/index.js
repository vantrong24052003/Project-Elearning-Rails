import { application } from "./application"
import FaqController from "./home/faq_controller";
import HeaderController from "./shared/header_controller";
import HeroController from "./home/hero_controller";
import LazyLoadingController from "./shared/lazy_loading_controller"
import AudioPlayerController from "./shared/audio_player_controller"
import DropdownController from "./shared/dropdown_controller";
import SidebarController from "./manage/sidebar_controller";
import CourseFilterController from "./dashboard/course_filter_controller";
import CourseSelectionController from "./dashboard/course_selection_controller";
import BulkActionController from "./dashboard/bulk_action_controller";
import price_slider_controller from "./dashboard/price_slider_controller";

// home
application.register("home--faq", FaqController);
application.register("home--hero", HeroController);

// dashboard
application.register("dashboard--course-filter", CourseFilterController);
application.register("dashboard--course-selection", CourseSelectionController);
application.register("dashboard--bulk-action", BulkActionController);
application.register("dashboard--price-slider", price_slider_controller);


// manage
application.register("manage--sidebar", SidebarController);

// shared
application.register("shared--lazy-loading", LazyLoadingController);
application.register("shared--audio-player", AudioPlayerController);
application.register("shared--header", HeaderController);
application.register("shared--dropdown", DropdownController);
