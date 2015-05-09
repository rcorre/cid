/// TODO: move this logic into Game
module dau.engine;

import std.string, std.algorithm;
import dau.allegro;
import dau.setup;
import dau.state;
import dau.system;
import dau.game;

// TODO: kill global state!
// global variables
ALLEGRO_EVENT_QUEUE* mainEventQueue;
ALLEGRO_TIMER* mainTimer;

alias AllegroEventHandler = void delegate(ALLEGRO_EVENT);

void registerEventHandler(AllegroEventHandler handler, ALLEGRO_EVENT_TYPE type) {
  _eventHandlers[type] ~= handler;
}

/// Initialize allegro, create a window, and being running the update/draw loop.
/// Params:
///   firstState = state to start the game in.
///   settings = options to configure the game instance
int runGame(State!Game firstState, GameSettings settings, System[] systems)
{
  return al_run_allegro({
    al_init();
    _settings = settings;

    al_set_new_display_option(ALLEGRO_DISPLAY_OPTIONS.ALLEGRO_VSYNC, 1, ALLEGRO_SUGGEST);
    mainEventQueue = al_create_event_queue();
    mainTimer = al_create_timer(1.0 / settings.fps);

    al_install_keyboard();
    al_install_mouse();
    al_install_joystick();
    al_install_audio();
    al_init_acodec_addon();
    al_init_image_addon();
    al_init_font_addon();
    al_init_ttf_addon();

    al_reserve_samples(settings.numAudioSamples);

    //al_register_event_source(mainEventQueue, al_get_display_event_source(mainDisplay));
    al_register_event_source(mainEventQueue, al_get_keyboard_event_source());
    al_register_event_source(mainEventQueue, al_get_mouse_event_source());
    al_register_event_source(mainEventQueue, al_get_timer_event_source(mainTimer));
    al_register_event_source(mainEventQueue, al_get_joystick_event_source());

    with(ALLEGRO_BLEND_MODE) {
      al_set_blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD, ALLEGRO_ALPHA,
          ALLEGRO_INVERSE_ALPHA);
    }

    runSetupFunctions();

    Game.start(systems, settings);
    Game.instance.states.push(firstState);

    al_start_timer(mainTimer); // start fps timer

    while(_run) {
      bool frameTick = processEvents();
      if (frameTick) {
        mainUpdate();
        mainDraw();
      }
    }

    runShutdownFunctions();

    return 0;
  });
}

void shutdownGame() {
  _run = false;
}

private:
bool _run = true;

// returns true if time to render next frame
bool processEvents() {
  ALLEGRO_EVENT event;
  al_wait_for_event(mainEventQueue, &event);
  switch(event.type)
  {
    case ALLEGRO_EVENT_TIMER:
      {
        if (event.timer.source == mainTimer) {
          return true;
        }
        break;
      }
    case ALLEGRO_EVENT_DISPLAY_CLOSE:
      {
        shutdownGame();
        break;
      }
    case ALLEGRO_EVENT_DISPLAY_RESIZE:
      {
        //al_acknowledge_resize(mainDisplay);
        break;
      }
    default:
  }
  foreach(handler ; _eventHandlers.get(event.type, null)) {
    handler(event);
  }
  return false;
}

void mainUpdate() {
  static float last_update_time = 0;
  float current_time = al_get_time();
  float delta = current_time - last_update_time;
  last_update_time = current_time;
  Game.instance.update(delta);
}

void mainDraw() {
  Game.instance.draw();
}

private:
AllegroEventHandler[][ALLEGRO_EVENT_TYPE] _eventHandlers;
ALLEGRO_BITMAP* _icon;
GameSettings _settings;
