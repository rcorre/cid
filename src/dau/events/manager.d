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
        bool handled = handler.handle(event);

        if (handled && handler.consume) break;
      }
    }
  }

  @property {
    auto controlScheme() { return _controls; }

    void controlScheme(ControlScheme controls) {
      _controls = controls;
      refreshHandlers(controls);
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

  auto onButtonDown(string name,
                    EventAction action,
                    ConsumeEvent consume = ConsumeEvent.no)
  {
    auto handler = new ButtonHandler(action, ButtonHandler.Type.press,
        _controls, name, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onButtonUp(string name,
                  EventAction action,
                  ConsumeEvent consume = ConsumeEvent.no)
  {
    auto handler = new ButtonHandler(action, ButtonHandler.Type.release,
        _controls, name, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAnyKeyDown(KeyAction action, ConsumeEvent consume = ConsumeEvent.no) {
    auto handler = new AnyKeyHandler(action, AnyKeyHandler.Type.press, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAnyKeyUp(KeyAction action, ConsumeEvent consume = ConsumeEvent.no) {
    auto handler = new AnyKeyHandler(action, AnyKeyHandler.Type.release, consume);
    _handlers.insert(handler);
    return handler;
  }

  auto onAxisMoved(string name,
                   AxisAction action,
                   ConsumeEvent consume = ConsumeEvent.yes)
  {
    auto handler = new AxisHandler(action, _controls, name, consume);
    _handlers.insert(handler);
    return handler;
  }

  // update handlers to listen to new controls after a control scheme change
  private auto refreshHandlers(ControlScheme controls) {
    foreach(h ; _handlers) h.updateControls(controls);
  }
}
