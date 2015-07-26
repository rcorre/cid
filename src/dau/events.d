module dau.events;

public import core.time;

import dau.allegro;
import dau.util.droplist;

enum MouseButton : uint {
  lmb = 1,
  rmb = 2
}

alias KeyCode = uint;

class EventManager {
  this() {
    _handlers = new HandlerList();
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

      foreach(handler ; _handlers) {
        if (handler.matches(event)) handler.handle(event);
      }
    }
  }

  auto after(float seconds, EventAction action) {
    enum repeat = false;
    auto handler = new TimerHandler(action, seconds, repeat, _queue);
    _handlers.insert(handler);
    return handler;
  }

  auto after(Duration dur, EventAction action) {
    return after(dur.total!"nsecs" / 1e9, action);
  }

  auto every(float seconds, EventAction action) {
    enum repeat = true;
    auto handler = new TimerHandler(action, seconds, repeat, _queue);
    _handlers.insert(handler);
    return handler;
  }

  auto every(Duration dur, EventAction action) {
    return every(dur.total!"nsecs" / 1e9, action);
  }

  auto onKeyDown(EventAction action) {
    auto handler = new KeyboardHandler(action, KeyboardHandler.Type.Press);
    _handlers.insert(handler);
    return handler;
  }

  auto onKeyUp(EventAction action) {
    auto handler = new KeyboardHandler(action, KeyboardHandler.Type.Release);
    _handlers.insert(handler);
    return handler;
  }

  auto onKeyChar(EventAction action) {
    auto handler = new KeyboardHandler(action, KeyboardHandler.Type.Char);
    _handlers.insert(handler);
    return handler;
  }

  private:
  alias HandlerList = DropList!(EventHandler, x => !x._active);

  ALLEGRO_EVENT_QUEUE* _queue;
  HandlerList          _handlers;
}

alias EventAction = void delegate(in ALLEGRO_EVENT);

abstract class EventHandler {
  private bool _active = true;

  void unregister() { _active = false; }

  bool matches(in ALLEGRO_EVENT ev);
  void handle(in ALLEGRO_EVENT ev);
}

class TimerHandler : EventHandler {
  private {
    EventAction          _action;
    bool                 _repeat;
    ALLEGRO_EVENT_QUEUE* _queue;
    ALLEGRO_TIMER*       _timer;
  }

  this(EventAction action, float secs, bool repeat, ALLEGRO_EVENT_QUEUE* queue) {
    _action = action;
    _repeat = repeat;
    _queue  = queue;
    _timer  = al_create_timer(secs);

    // register and start timer
    al_register_event_source(_queue, al_get_timer_event_source(_timer));
    al_start_timer(_timer);
  }

  override void unregister() {
    super.unregister();

    al_unregister_event_source(_queue, al_get_timer_event_source(_timer));
    al_destroy_timer(_timer);
  }

  override bool matches(in ALLEGRO_EVENT ev) {
    return ev.type == ALLEGRO_EVENT_TIMER && ev.timer.source == _timer;
  }

  override void handle(in ALLEGRO_EVENT ev) {
    _action(ev);
    if (!_repeat) unregister();
  }
}

class KeyboardHandler : EventHandler {
  private {
    enum Type {
      Press,
      Release,
      Char
    }

    EventAction _action;
    Type   _type;
  }

  this(EventAction action, Type type) {
    _action = action;
    _type   = type;
  }

  override bool matches(in ALLEGRO_EVENT ev) {
    return
      ev.type == ALLEGRO_EVENT_KEY_DOWN && _type == Type.Press   ||
      ev.type == ALLEGRO_EVENT_KEY_UP   && _type == Type.Release ||
      ev.type == ALLEGRO_EVENT_KEY_CHAR && _type == Type.Char;
  }

  override void handle(in ALLEGRO_EVENT ev) {
    _action(ev);
  }
}
