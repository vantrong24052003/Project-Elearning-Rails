import { application } from "./application"
import FaqController from "./home/faq_controller";
import HeaderController from "./shared/header_controller";
import HeroController from "./home/hero_controller";
import PriceSliderController from "./shared/price_slider_controller";
import LazyLoadingController from "./shared/lazy_loading_controller"
import AudioPlayerController from "./shared/audio_player_controller"
import DropdownController from "./shared/dropdown_controller";
import SidebarController from "./manage/sidebar_controller";
import CourseFilterController from "./dashboard/course_filter_controller";

// home
application.register("home--faq", FaqController);
application.register("home--hero", HeroController);

// dashboard
application.register("dashboard--course-filter", CourseFilterController);

// manage
application.register("manage--sidebar", SidebarController);

// shared
application.register("shared--price-slider", PriceSliderController);
application.register("shared--lazy-loading", LazyLoadingController);
application.register("shared--audio-player", AudioPlayerController);
application.register("shared--header", HeaderController);
application.register("shared--dropdown", DropdownController);
