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

import std.path : exists, setExtension, buildNormalizedPath;
import cid.util.content;

class GraphicsManager {
  alias renderer this;

  private {
    Display  _display;
    Renderer _renderer;

    ContentCache!bitmapLoader _bitmaps;
    ContentCache!fontLoader   _fonts;
  }

  @property {
    auto display() { return _display; }
    auto renderer() { return _renderer; }

    auto bitmaps() { return _bitmaps; }
    auto fonts() { return _fonts; }
  }

  this(Display.Settings settings) {
    _display = Display(settings);
    _renderer = new Renderer;
  }

  static auto bitmapLoader(string key) {
    auto path = contentDir
      .buildNormalizedPath(bitmapDir, key)
      .setExtension(bitmapExt);

    assert(path.exists, "could not find %s".format(path));
    return Bitmap.load(path);
  }

  static auto fontLoader(string key, int size) {
    auto path = contentDir
      .buildNormalizedPath(fontDir, key)
      .setExtension(fontExt);

    assert(path.exists, "could not find %s".format(path));
    return loadFont(path, size);
  }
}

private:
enum {
  contentDir = "content",

  bitmapDir = "image",
  fontDir   = "font",

  bitmapExt = ".png",
  fontExt   = ".ttf",
}
