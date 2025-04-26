import { application } from "./application"
import audio_player_controller from "./shared/audio_player_controller";
import header_controler from "./shared/header_controller";
import dropdown_controller from "./shared/dropdown_controller";
import faq_controller from "./home/faq_controller";
import hero_controller from "./home/hero_controller";
import course_filter_controller from "./dashboard/course_filter_controller";
import course_selection_controller from "./dashboard/course_selection_controller";
import bulk_action_controller from "./dashboard/bulk_action_controller";
import price_slider_controller from "./dashboard/price_slider_controller";
import sidebar_controller from "./manage/sidebar_controller";
import lazy_loading_controller from "./shared/lazy_loading_controller";
import tabs_controller from "./dashboard/tabs_controller";
import accordion_controller from "./dashboard/accordion_controller";

// home
application.register("home--faq", faq_controller);
application.register("home--hero", hero_controller);

// shared
application.register("shared--audio-player", audio_player_controller);
application.register("shared--header", header_controler);
application.register("shared--dropdown", dropdown_controller);
application.register("shared--lazy-loading", lazy_loading_controller);

// dashboard
application.register("dashboard--course-filter", course_filter_controller);
application.register("dashboard--course-selection", course_selection_controller);
application.register("dashboard--bulk-action", bulk_action_controller);
application.register("dashboard--price-slider", price_slider_controller);
application.register("dashboard--tabs", tabs_controller);
application.register("dashboard--accordion", accordion_controller);

// manage
application.register("manage--sidebar", sidebar_controller);
