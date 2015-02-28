module dau.input;

import std.algorithm : max, min, any;
import dau.setup;
import dau.allegro;
import dau.geometry.vector;

private enum MouseButton {
  lmb = 1,
  rmb = 2
}

private enum Keymap {
  left  = [ALLEGRO_KEY_A],
  right = [ALLEGRO_KEY_D],
  up    = [ALLEGRO_KEY_W],
  down  = [ALLEGRO_KEY_S],

  action1 = [ALLEGRO_KEY_Q],
  action2 = [ALLEGRO_KEY_E],
  undo    = [ALLEGRO_KEY_U],

  skip  = [ALLEGRO_KEY_SPACE],
  exit  = [ALLEGRO_KEY_ESCAPE],
}

class InputManager {
  this() {
    al_get_keyboard_state(&_curKeyboardState);
    al_get_mouse_state(&_curMouseState);
  }

  void update(float time) {
    _prevKeyboardState = _curKeyboardState;
    _prevMouseState = _curMouseState;
    al_get_keyboard_state(&_curKeyboardState);
    al_get_mouse_state(&_curMouseState);
  }

  @property {
    Vector2f scrollDirection() {
      Vector2f scroll = Vector2f.zero;
      if (keyHeld(Keymap.up)) {
        scroll.y = -1;
      }
      else if (keyHeld(Keymap.down)) {
        scroll.y = 1;
      }
      if (keyHeld(Keymap.left)) {
        scroll.x = -1;
      }
      else if (keyHeld(Keymap.right)) {
        scroll.x = 1;
      }
      return scroll;
    }

    bool selectUp()    { return keyPressed(Keymap.up); }
    bool selectDown()  { return keyPressed(Keymap.down); }
    bool selectLeft()  { return keyPressed(Keymap.left); }
    bool selectRight() { return keyPressed(Keymap.right); }

    bool skip()    { return keyPressed(Keymap.skip); }
    bool exit()    { return keyPressed(Keymap.exit); }
    bool undo()    { return keyPressed(Keymap.undo); }
    bool action1() { return keyHeld(Keymap.action1); }
    bool action2() { return keyHeld(Keymap.action2); }

    bool select()  { return mouseClicked(MouseButton.lmb); }
    bool inspect() { return mouseHeld(MouseButton.rmb); }
  }

  Vector2i mousePos() {
    return Vector2i(_curMouseState.x, _curMouseState.y);
  }

  Vector2i prevMousePos() {
    return Vector2i(_prevMouseState.x, _prevMouseState.y);
  }

  private:
  bool keyHeld(Keymap buttons) {
    return buttons.any!(key => al_key_down(&_curKeyboardState, key));
  }

  bool keyPressed(Keymap buttons) {
    return buttons.any!(key => !al_key_down(&_prevKeyboardState, key) && al_key_down(&_curKeyboardState, key));
  }

  bool keyReleased(int keycode) {
    return al_key_down(&_prevKeyboardState, keycode) && !al_key_down(&_curKeyboardState, keycode);
  }

  bool mouseClicked(MouseButton button) {
    int b = cast(int) button;
    return !al_mouse_button_down(&_prevMouseState, b) && al_mouse_button_down(&_curMouseState, b);
  }

  bool mouseHeld(MouseButton button) {
    int b = cast(int) button;
    return al_mouse_button_down(&_curMouseState, b);
  }

  ALLEGRO_KEYBOARD_STATE _curKeyboardState, _prevKeyboardState;
  ALLEGRO_MOUSE_STATE _curMouseState, _prevMouseState;
}
