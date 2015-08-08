module dau.events.manager;

import core.time;
import dau.allegro;
import dau.util.droplist;
import dau.events.input;
import dau.events.handlers;

class EventManager {
  private {
    alias HandlerList = DropList!(EventHandler, x => !x.active);

    ALLEGRO_EVENT_QUEUE* _queue;
    HandlerList          _handlers;
    ControlScheme        _controls;
  }

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
        handler.handle(event);
      }
    }
  }

  @property {
    auto controlScheme() { return _controls; }

    void controlScheme(ControlScheme controls) {
      //TODO: remap existing handlers?
      _controls = controls;
    }
  }

  auto after(double seconds, EventAction action) {
    enum repeat = false;
    auto handler = new TimerHandler(action, seconds, repeat, _queue);
    _handlers.insert(handler);
    return handler;
  }

  auto after(Duration dur, EventAction action) {
    return after(dur.total!"nsecs" / 1e9, action);
  }

  auto every(double seconds, EventAction action) {
    enum repeat = true;
    auto handler = new TimerHandler(action, seconds, repeat, _queue);
    _handlers.insert(handler);
    return handler;
  }

  auto every(Duration dur, EventAction action) {
    return every(dur.total!"nsecs" / 1e9, action);
  }

  auto onButtonDown(string name, EventAction action) {
    return registerButtonHandler(name, ButtonHandler.Type.press, action);
  }

  auto onButtonUp(string name, EventAction action) {
    return registerButtonHandler(name, ButtonHandler.Type.press, action);
  }

  auto onAnyKeyDown(KeyAction action) {
    auto handler = new AnyKeyHandler(action, AnyKeyHandler.Type.press);
    _handlers.insert(handler);
    return handler;
  }

  auto onAnyKeyUp(KeyAction action) {
    auto handler = new AnyKeyHandler(action, AnyKeyHandler.Type.release);
    _handlers.insert(handler);
    return handler;
  }

  private auto registerButtonHandler(string name,
                                     ButtonHandler.Type type,
                                     EventAction action)
  {
    assert(name in _controls.buttons, "unknown button name " ~ name);

    auto map = _controls.buttons[name];
    auto handler = new ButtonHandler(action, type, map);

    _handlers.insert(handler);
    return handler;
  }

  auto onAxisMoved(string name, AxisAction action) {
    assert(name in _controls.axes, "unknown axis name " ~ name);

    auto handler = new AxisHandler(action, _controls.axes[name]);
    _handlers.insert(handler);
    return handler;
  }
}
