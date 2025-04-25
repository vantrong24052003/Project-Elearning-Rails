import { application } from "./application"
import lazy_loading_controller from "./shared/lazy_loading_controller";
import audio_player_controller from "./shared/audio_player_controller";
import header_controler from "./shared/header_controller";
import dropdown_controller from "./shared/dropdown_controller";

import faq_controller from "./home/faq_controller";
import hero_controller from "./home/hero_controller";

// home
application.register("home--faq", faq_controller);
application.register("home--hero", hero_controller);

// shared
application.register("shared--lazy-loading", lazy_loading_controller);
application.register("shared--audio-player", audio_player_controller);
application.register("shared--header", header_controler);
application.register("shared--dropdown", dropdown_controller);
