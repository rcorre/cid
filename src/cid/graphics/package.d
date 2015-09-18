/**
 * Package containing all graphics-related modules
 */
module cid.graphics;

public import cid.graphics.font;
public import cid.graphics.text;
public import cid.graphics.blend;
public import cid.graphics.color;
public import cid.graphics.bitmap;
public import cid.graphics.render;
public import cid.graphics.sprite;
public import cid.graphics.display;
public import cid.graphics.primitive;

class GraphicsManager {
  alias renderer this;

  private {
    Display  _display;
    Renderer _renderer;
  }

  @property {
    auto display() { return _display; }
    auto renderer() { return _renderer; }
  }

  this(Display.Settings settings) {
    _display = Display(settings);
    _renderer = new Renderer;
  }
}
