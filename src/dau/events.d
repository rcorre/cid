module dau.events;

public import core.time;

import std.algorithm;
import dau.allegro;

enum MouseButton : uint {
  lmb = 1,
  rmb = 2
}

alias KeyCode = uint;

class EventManager {
  this() {
    _queue = al_create_event_queue();

    al_register_event_source(_queue, al_get_keyboard_event_source());
    al_register_event_source(_queue, al_get_mouse_event_source());
    al_register_event_source(_queue, al_get_joystick_event_source());
  }

  ~this() {
    al_destroy_event_queue(_queue);
  }

  /**
   * Process events until the event queue is empty.
   */
  void process() {
    ALLEGRO_EVENT event;

    while (!al_is_event_queue_empty(_queue)) {
      al_wait_for_event(_queue, &event);

      switch (event.type) {
        case ALLEGRO_EVENT_TIMER:
          auto entry = event.timer.source in _timerEntries;
          if (entry !is null) {
            entry.action();
            if (!entry.repeat) stopTimer(entry.timer);
          }
          break;
          //case ALLEGRO_EVENT_DISPLAY_CLOSE:
          //  stop();
          //  break;
          //case ALLEGRO_EVENT_DISPLAY_RESIZE:
          //  //al_acknowledge_resize(mainDisplay);
          //  break;
        default:
      }
    }
  }

  auto trigger(void delegate() action) {
    struct RegisterTrigger {
      private EventManager _parent;
      private void delegate() _action;

      auto after(Duration dur) { return _parent.createTimer(dur, action, false); }
      auto every(Duration dur) { return _parent.createTimer(dur, action, true); }
    }

    return RegisterTrigger(this);
  }

  auto stopTimer(Timer timer) {
    assert(timer in _timerEntries, "Failed to find timer to stop");

    auto entry = _timerEntries[timer];

    al_unregister_event_source(_queue, al_get_timer_event_source(entry.timer));
    al_destroy_timer(entry.timer);

    _timerEntries.remove(timer);
  }

  private:
  ALLEGRO_EVENT_QUEUE *_queue;
  TimerEntry[Timer] _timerEntries;

  struct TimerEntry {
    Timer           timer;
    void delegate() action;
    bool            repeat;
  }

  private auto createTimer(Duration dur, void delegate() action, bool repeat) {
    TimerEntry entry;

    auto timer = al_create_timer(dur.total!"seconds" / 1e9);

    entry.repeat = repeat;
    entry.timer  = timer;
    entry.action = action;

    _timerEntries[timer] = entry;

    al_register_event_source(_queue, al_get_timer_event_source(timer));
    al_start_timer(timer);

    return timer;
  }
}

alias Timer = ALLEGRO_TIMER*;
