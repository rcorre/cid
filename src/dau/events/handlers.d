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
