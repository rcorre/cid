module dau.events.handlers;

import std.traits    : EnumMembers;
import std.container : Array;
import std.algorithm : any;
import dau.allegro;
import dau.geometry;
import dau.events.input;

alias EventAction = void delegate();
alias AxisAction = void delegate(Vector2f axisPos);

abstract class EventHandler {
  private bool _active = true;

  @property bool active() { return active; }

  void unregister() { _active = false; }

  void handle(in ALLEGRO_EVENT ev);
}

class TimerHandler : EventHandler {
  private {
    EventAction          _action;
    bool                 _repeat;
    ALLEGRO_EVENT_QUEUE* _queue;
    ALLEGRO_TIMER*       _timer;
  }

  this(EventAction action, double secs, bool repeat, ALLEGRO_EVENT_QUEUE* queue) {
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

  override void handle(in ALLEGRO_EVENT ev) {
    if (ev.type == ALLEGRO_EVENT_TIMER && ev.timer.source == _timer) {
      _action();
      if (!_repeat) unregister();
    }
  }
}

class ButtonHandler : EventHandler {
  enum Type { press, release }

  private {
    EventAction _action;
    Type        _type;
    Array!int   _keys;
    Array!int   _buttons;
  }

  this(EventAction action, Type type, ButtonMap map) {
    _action  = action;
    _type    = type;
    _keys    = map.keys;
    _buttons = map.buttons;
  }

  override void handle(in ALLEGRO_EVENT ev) {
    final switch (_type) with (Type) {
      case press:
        if (_keys[].any!(x => ev.isKeyPress(x)) ||
            _buttons[].any!(x => ev.isButtonPress(x)))
        {
          _action();
        }
        break;
      case release:
        if (_keys[].any!(x => ev.isKeyRelease(x)) ||
            _buttons[].any!(x => ev.isButtonRelease(x)))
        {
          _action();
        }
        break;
    }
  }
}

class AxisHandler : EventHandler {
  private {
    AxisMap    _map;
    AxisAction _action;

    bool[nDirections] _dpad;
    Vector2f          _joystick;
  }

  this(AxisAction action, AxisMap map) {
    _map      = map;
    _action   = action;
    _joystick = Vector2f.zero;
  }

  override void handle(in ALLEGRO_EVENT ev) {
    with (Direction) {
      if      (ev.isKeyPress  (_map.keys[down])) dpad(down, true);
      else if (ev.isKeyRelease(_map.keys[down])) dpad(down, false);

      else if (ev.isKeyPress  (_map.keys[up])) dpad(up, true);
      else if (ev.isKeyRelease(_map.keys[up])) dpad(up, false);

      else if (ev.isKeyPress  (_map.keys[left])) dpad(left, true);
      else if (ev.isKeyRelease(_map.keys[left])) dpad(left, false);

      else if (ev.isKeyPress  (_map.keys[right])) dpad(right, true);
      else if (ev.isKeyRelease(_map.keys[right])) dpad(right, false);

      else if (ev.isAxisMotion(_map.xAxis)) joystickX(ev.joystick.pos);
      else if (ev.isAxisMotion(_map.yAxis)) joystickY(ev.joystick.pos);
    }
  }

  private:
  void joystickY(float val) {
    _joystick.y = val;
    _action(_joystick);
  }

  void joystickX(float val) {
    _joystick.x = val;
    _action(_joystick);
  }

  void dpad(Direction direction, bool pressed) {
    // record the button state
    _dpad[direction] = pressed;

    // generate a joystick position from the current button states
    Vector2f pos;

    if (_dpad[Direction.up])    pos.y -= 1;
    if (_dpad[Direction.down])  pos.y += 1;
    if (_dpad[Direction.left])  pos.x -= 1;
    if (_dpad[Direction.right]) pos.x += 1;

    // trigger the registered action
    _action(pos);
  }
}

private:
bool isKeyPress(in ALLEGRO_EVENT ev, int keycode) {
  return ev.type == ALLEGRO_EVENT_KEY_DOWN &&
    ev.keyboard.keycode == keycode;
}

bool isKeyRelease(in ALLEGRO_EVENT ev, int keycode) {
  return ev.type == ALLEGRO_EVENT_KEY_UP &&
    ev.keyboard.keycode == keycode;
}

bool isButtonPress(in ALLEGRO_EVENT ev, int button) {
  return ev.type == ALLEGRO_EVENT_JOYSTICK_BUTTON_DOWN &&
    ev.joystick.button == button;
}

bool isButtonRelease(in ALLEGRO_EVENT ev, int button) {
  return ev.type == ALLEGRO_EVENT_JOYSTICK_BUTTON_UP &&
    ev.joystick.button == button;
}

bool isAxisMotion(in ALLEGRO_EVENT ev, AxisMap.SubAxis map) {
  return (ev.type == ALLEGRO_EVENT_JOYSTICK_AXIS &&
      ev.joystick.stick == map.stick &&
      ev.joystick.axis == map.axis);
}

unittest {
  int runTest() {
    al_init();

    ALLEGRO_EVENT event_in, event_out;
    ALLEGRO_EVENT_SOURCE source;

    auto queue = al_create_event_queue();

    al_init_user_event_source(&source);
    al_register_event_source(queue, &source);

    event_in.any.type         = ALLEGRO_EVENT_KEY_DOWN;
    event_in.keyboard.keycode = ALLEGRO_KEY_ENTER;

    al_emit_user_event(&source, &event_in, null);

    al_wait_for_event(queue, &event_out);

    assert(event_out.type == ALLEGRO_EVENT_KEY_DOWN);
    assert(event_out.keyboard.keycode == ALLEGRO_KEY_ENTER);

    al_destroy_event_queue(queue);
    return 0;
  }

  int res = al_run_allegro(&runTest);
  assert(res == 0);
}

// test button handling
unittest {
  class FakeHandler : ButtonHandler {
    bool handled;

    // handle the event, then return and reset the handled flag
    bool check(in ALLEGRO_EVENT ev) {
      super.handle(ev);
      auto res = handled;
      handled = false;
      return res;
    }

    this(Type type, ButtonMap map) {
      super({ handled = true; }, type, map);
    }
  }

  ButtonMap confirmMap, cancelMap;

  confirmMap.keys    = [ ALLEGRO_KEY_ENTER, ALLEGRO_KEY_J ];
  confirmMap.buttons = [ 0, 2 ];

  cancelMap.keys    = [ ALLEGRO_KEY_ESCAPE, ALLEGRO_KEY_K ];
  cancelMap.buttons = [ 1 ];

  auto confirmHandler = new FakeHandler(ButtonHandler.Type.press, confirmMap);
  auto cancelHandler  = new FakeHandler(ButtonHandler.Type.release, cancelMap);

  auto buttonDown(int button) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_JOYSTICK_BUTTON_DOWN;
    ev.joystick.button = button;

    return ev;
  }

  auto buttonUp(int button) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_JOYSTICK_BUTTON_UP;
    ev.joystick.button = button;

    return ev;
  }

  auto keyDown(int key) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_KEY_DOWN;
    ev.keyboard.keycode = key;
    return ev;
  }

  auto keyUp(int key) {
    ALLEGRO_EVENT ev;
    ev.any.type = ALLEGRO_EVENT_KEY_UP;
    ev.keyboard.keycode = key;
    return ev;
  }

  // confirm handler should respond to:
  // - button presses, not releases
  //   - joystick buttons 0 and 2
  //   - keys enter and j
  assert( confirmHandler.check(buttonDown(0)));
  assert( confirmHandler.check(buttonDown(2)));
  assert(!confirmHandler.check(buttonDown(1)));
  assert(!confirmHandler.check(buttonUp  (0)));
  assert(!confirmHandler.check(buttonUp  (2)));

  assert( confirmHandler.check(keyDown(ALLEGRO_KEY_ENTER)));
  assert( confirmHandler.check(keyDown(ALLEGRO_KEY_J)));
  assert(!confirmHandler.check(keyDown(ALLEGRO_KEY_ESCAPE)));
  assert(!confirmHandler.check(keyUp  (ALLEGRO_KEY_ENTER)));
  assert(!confirmHandler.check(keyUp  (ALLEGRO_KEY_ESCAPE)));

  // confirm handler should respond to:
  // - button releases, not presses
  //   - joystick button 1
  //   - keys escape and k
  assert(!cancelHandler.check(buttonDown(1)));
  assert(!cancelHandler.check(buttonDown(0)));
  assert( cancelHandler.check(buttonUp  (1)));
  assert(!cancelHandler.check(buttonUp  (0)));

  assert(!cancelHandler.check(keyDown(ALLEGRO_KEY_ESCAPE)));
  assert(!cancelHandler.check(keyDown(ALLEGRO_KEY_K)));
  assert(!cancelHandler.check(keyDown(ALLEGRO_KEY_ENTER)));
  assert(!cancelHandler.check(keyUp  (ALLEGRO_KEY_ENTER)));
  assert( cancelHandler.check(keyUp  (ALLEGRO_KEY_ESCAPE)));
}
