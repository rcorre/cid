module dau.gui.messagebox;

import std.string, std.conv, std.container : DList;
import dau.gui.element;
import dau.gui.data;
import dau.gui.textbox;
import dau.geometry.all;
import dau.graphics.all;

class MessageBox : GUIElement {
  this(GUIData data) {
    _font = Font(data["fontName"], data["fontSize"].to!int);
    auto pos = data.get("offset", "0,0").parseVector!int;
    auto anchor = data.get("anchor", "topLeft").to!Anchor;
    _textBuffer = data.get("textBuffer", "0,0").parseVector!int;
    _maxLines = ("maxLines" in data) ? data["maxLines"].to!int : int.max;
    _charLimit = ("charLimit" in data) ? data["charLimit"].to!int : int.max;
    super(data, pos, anchor);
    addChild!TextBox("label");
  }

  override void draw(Vector2i parentTopLeft) {
    super.draw(parentTopLeft);
    auto drawPos = area.bottomLeft + parentTopLeft + _textBuffer;
    foreach(post ; _messages) {
      drawPos.y -= _font.heightOf(post.message.wrap(_charLimit));
      _font.draw(post.message, drawPos, post.color);
    }
  }

  void postMessage(string message, Color color = Color.black) {
    _messages.insertFront(Post(message, color));
    if (_numLines >= _maxLines) { _messages.removeBack; }
    else { ++_numLines; }
  }

  private:
  Font _font;
  DList!Post _messages;
  Vector2i _textBuffer;
  int _maxLines, _numLines, _charLimit;

  struct Post {
    string message;
    Color color;
  }
}
