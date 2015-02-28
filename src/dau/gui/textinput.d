module dau.gui.textinput;

import std.conv, std.string, std.range, std.regex;
import dau.input;
import dau.allegro;
import dau.engine;
import dau.util.func;
import dau.gui.element;
import dau.gui.data;
import dau.gui.textbox;
import dau.geometry.all;
import dau.graphics.all;

class TextInput : GUIElement {
  alias Action = void delegate(string);
  this(GUIData data, Action action = doNothing!Action) {
    auto pos = data.get("offset", "0,0").parseVector!int;
    auto anchor = data.get("anchor", "topLeft").to!Anchor;
    super(data, pos, anchor);

    _textBox = new TextBox(data.child["text"]);
    addChild(_textBox);

    _charLimit = ("charLimit" in data) ? data["charLimit"].to!int : int.max;
    _validate = data.get("validate", ".*").regex;

    _focusedTint = data.get("focusedTint", "1, 1, 1").parseColor;
    _unfocusedTint = data.get("unfocusedTint", "0.5, 0.5, 0.5").parseColor;
    _invalidTint = data.get("invalidTint", "1.0, 0.0, 0.0").parseColor;
    sprite.tint = _unfocusedTint;

    if ("cursorTexture" in data && "cursorAnimation" in data) {
      _cursor = new Animation(data["cursorTexture"], data["cursorAnimation"], Animation.Repeat.loop);
      _cursor.scale = data.get("scale", "1,1").parseVector!float;
    }

    registerEventHandler(&handleKeyChar, ALLEGRO_EVENT_KEY_CHAR);
    _action = action;
  }

  @property {
    string text() { return _textBox.text; }
    void text(string val) {
      _textBox.text = val.take(_charLimit).to!string;
      sprite.tint = isValid ? _focusedTint : _invalidTint ;
    }

    bool isValid() { return !text.matchFirst(_validate).empty; }
  }

  override {
    void update(float time) {
      super.update(time);
      if (hasFocus && _cursor !is null) { _cursor.update(time); }
    }

    void draw(Vector2i parentTopLeft) {
      super.draw(parentTopLeft);
      if (hasFocus && _cursor !is null) {
        auto offset = parentTopLeft + area.topLeft + Vector2i(0, _textBox.height / 2);
        _cursor.draw(offset + _textBox.textArea.topRight);
      }
    }

    void onFocus(bool focus) {
      if (focus) {
        sprite.tint = isValid ? _focusedTint : _invalidTint ;
      }
      else {
        sprite.tint = _unfocusedTint;
      }
    }
  }

  private:
  TextBox _textBox;
  int _charLimit;
  Color _focusedTint, _unfocusedTint, _invalidTint;
  Animation _cursor;
  Regex!char _validate;
  Action _action;

  void handleKeyChar(ALLEGRO_EVENT event) {
    if (!hasFocus) { return; }
    if (event.keyboard.keycode == ALLEGRO_KEY_ENTER) {
      _action(text);
    }
    else if (event.keyboard.keycode == ALLEGRO_KEY_BACKSPACE) {
      text = text.chop;
    }
    else {
      text = text ~ cast(char) event.keyboard.unichar;
    }
  }
}

