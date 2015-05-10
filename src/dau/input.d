module dau.input;

import std.algorithm : max, min, any;
import dau.allegro;
import dau.geometry.vector;

enum MouseButton : uint {
  lmb = 1,
  rmb = 2
}

alias KeyCode = uint;

class InputManager {
  this() {
    al_get_keyboard_state(&_curKeyboardState);
    al_get_mouse_state(&_curMouseState);
  }

  void update() {
    _prevKeyboardState = _curKeyboardState;
    _prevMouseState = _curMouseState;
    al_get_keyboard_state(&_curKeyboardState);
    al_get_mouse_state(&_curMouseState);
  }

  Vector2i mousePos() {
    return Vector2i(_curMouseState.x, _curMouseState.y);
  }

  Vector2i prevMousePos() {
    return Vector2i(_prevMouseState.x, _prevMouseState.y);
  }

  bool keyHeld(KeyCode key) {
    return al_key_down(&_curKeyboardState, key);
  }

  bool keyPressed(KeyCode key) {
    return !al_key_down(&_prevKeyboardState, key) && al_key_down(&_curKeyboardState, key);
  }

  bool keyReleased(KeyCode key) {
    return al_key_down(&_prevKeyboardState, key) && !al_key_down(&_curKeyboardState, key);
  }

  bool mousePressed(MouseButton b) {
    return !al_mouse_button_down(&_prevMouseState, b) && al_mouse_button_down(&_curMouseState, b);
  }

  bool mouseReleased(MouseButton b) {
    return al_mouse_button_down(&_prevMouseState, b) && !al_mouse_button_down(&_curMouseState, b);
  }

  bool mouseHeld(MouseButton b) {
    return al_mouse_button_down(&_curMouseState, b);
  }

  private:
  ALLEGRO_KEYBOARD_STATE _curKeyboardState, _prevKeyboardState;
  ALLEGRO_MOUSE_STATE _curMouseState, _prevMouseState;
}
