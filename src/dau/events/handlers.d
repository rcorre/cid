module dau.events.handlers;

import std.conv      : to;
import std.traits    : EnumMembers;
import std.container : Array;
import std.algorithm : any;
import dau.allegro;
import dau.geometry;
import dau.events.input;
import dau.events.keycodes;

alias EventAction = void delegate();
alias AxisAction = void delegate(Vector2f axisPos);
alias KeyAction = void delegate(KeyCode key);

abstract class EventHandler {
  private bool _active = true;

  @property bool active() { return _active; }

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
  private enum Direction : ubyte { up, down, left, right };

  private {
    AxisMap    _map;
    AxisAction _action;

    bool[4]  _dpad;
    Vector2f _joystick;
  }

  this(AxisAction action, AxisMap map) {
    _map      = map;
    _action   = action;
    _joystick = Vector2f.zero;
  }

  override void handle(in ALLEGRO_EVENT ev) {
    with (Direction) {
      if      (ev.isKeyPress  (_map.downKey)) dpad(down, true);
      else if (ev.isKeyRelease(_map.downKey)) dpad(down, false);

      else if (ev.isKeyPress  (_map.upKey)) dpad(up, true);
      else if (ev.isKeyRelease(_map.upKey)) dpad(up, false);

      else if (ev.isKeyPress  (_map.leftKey)) dpad(left, true);
      else if (ev.isKeyRelease(_map.leftKey)) dpad(left, false);

      else if (ev.isKeyPress  (_map.rightKey)) dpad(right, true);
      else if (ev.isKeyRelease(_map.rightKey)) dpad(right, false);

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

class AnyKeyHandler : EventHandler {
  enum Type { press, release }

  private {
    KeyAction _action;
    Type      _type;
  }

  this(KeyAction action, Type type) {
    _action  = action;
    _type    = type;
  }

  override void handle(in ALLEGRO_EVENT ev) {
    if (_type == Type.press && ev.type == ALLEGRO_EVENT_KEY_DOWN) {
      _action(ev.keyboard.keycode.to!KeyCode);
    }
    else if (_type == Type.release && ev.type == ALLEGRO_EVENT_KEY_UP) {
      _action(ev.keyboard.keycode.to!KeyCode);
    }
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
  import dau.events.keycodes;

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

  confirmMap.keys    = [ KeyCode.enter, KeyCode.j ];
  confirmMap.buttons = [ 0, 2 ];

  cancelMap.keys    = [ KeyCode.escape, KeyCode.k ];
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

// test axis handling
unittest {
  import dau.events.keycodes;

  enum {
    xAxis     = 0,
    yAxis     = 1,
    goodStick = 1,
    badStick  = 0,
    badAxis   = 2,
  }

  AxisMap testAxis;

  testAxis.upKey    = KeyCode.w;
  testAxis.downKey  = KeyCode.s;
  testAxis.leftKey  = KeyCode.a;
  testAxis.rightKey = KeyCode.d;

  testAxis.xAxis.stick = 1;
  testAxis.xAxis.axis  = 0;

  testAxis.yAxis.stick = 1;
  testAxis.yAxis.axis  = 1;

  Vector2f axisPos = Vector2f.zero;

  bool check(Vector2f expected) {
    bool ok = axisPos.approxEqual(expected);
    axisPos = Vector2f.zero;
    return ok;
  }

  auto moveHandler = new AxisHandler((pos) { axisPos = pos; }, testAxis);

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

  auto moveAxis(int stick, int axis, float pos) {
    ALLEGRO_EVENT ev;
    ev.any.type       = ALLEGRO_EVENT_JOYSTICK_AXIS;
    ev.joystick.stick = stick;
    ev.joystick.axis  = axis;
    ev.joystick.pos   = pos;
    return ev;
  }

  // up
  moveHandler.handle(keyDown(ALLEGRO_KEY_W));
  assert(check(Vector2f(0, -1)));

  // up+right
  moveHandler.handle(keyDown(ALLEGRO_KEY_D));
  assert(check(Vector2f(1, -1)));

  // up+right+down (down+up should cancel)
  moveHandler.handle(keyDown(ALLEGRO_KEY_S));
  assert(check(Vector2f(1, 0)));

  // down+right (released up)
  moveHandler.handle(keyUp(ALLEGRO_KEY_W));
  assert(check(Vector2f(1, 1)));

  // down (released right)
  moveHandler.handle(keyUp(ALLEGRO_KEY_D));
  assert(check(Vector2f(0, 1)));

  // everything released
  moveHandler.handle(keyUp(ALLEGRO_KEY_S));
  assert(check(Vector2f.zero));

  // move the joystick x axis
  moveHandler.handle(moveAxis(goodStick, xAxis, 0.5f));
  assert(check(Vector2f(0.5f, 0)));

  // move the joystick y axis
  moveHandler.handle(moveAxis(goodStick, yAxis, 0.7f));
  assert(check(Vector2f(0.5f, 0.7f)));

  // move the joystick x axis in the other direction
  moveHandler.handle(moveAxis(goodStick, xAxis, -0.2f));
  assert(check(Vector2f(-0.2f, 0.7f)));

  // move a different axis on the same stick (should have no effect)
  moveHandler.handle(moveAxis(goodStick, badAxis, -0.9f));
  assert(check(Vector2f.zero));

  // move a different stick (should have no effect)
  moveHandler.handle(moveAxis(badStick, xAxis, -0.9f));
  assert(check(Vector2f.zero));

  // move the joystick y axis to zero
  moveHandler.handle(moveAxis(goodStick, yAxis, 0.0f));
  assert(check(Vector2f(-0.2f, 0.0f)));

  // move the joystick x axis to zero
  moveHandler.handle(moveAxis(goodStick, xAxis, 0.0f));
  assert(check(Vector2f(-0.0f, 0.0f)));
}
