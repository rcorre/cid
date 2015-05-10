module dau.graphics.display;

import std.algorithm : min;
import dau.allegro;
import dau.geometry;
import dau.graphics.color;
import jsonizer;

/// Represents the game window and the drawing canvas (backbuffer)
struct Display {
  /// Graphics and display configuration options.
  struct Settings {
    mixin JsonizeMe;
    @jsonize {
      Vector2i displaySize; /// Size of the game window
      Vector2i canvasSize;  /// Size of the backbuffer upon which graphics are rendered
      Color    color;       /// Color used to clear screen
    }
  }

  private {
    Color             _color;
    Vector2i          _canvasSize;
    ALLEGRO_DISPLAY*  _display;
    ALLEGRO_TRANSFORM _transform;
  }

  @disable this();

  this(Settings settings) {
    _display = al_create_display(settings.displaySize.x, settings.displaySize.y);
    _canvasSize = settings.canvasSize;

    with(ALLEGRO_BLEND_MODE) {
      al_set_blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD, ALLEGRO_ALPHA,
          ALLEGRO_INVERSE_ALPHA);
    }
  }

  @property {
    /// Size of the game window
    auto displaySize() {
      return Vector2i(al_get_display_width(_display), al_get_display_height(_display));
    }

    /// Set the size of the game window.
    /// Will modify the display transform accordingly.
    void displaySize(Vector2i size) {
      al_resize_display(_display, size.x, size.y);
      setDisplayTransform();
    }

    /// Size of the area alloted for drawing graphics.
    auto canvasSize() { return _canvasSize; }

    /// Set the size of the area alloted for drawing graphics.
    /// Will modify the display transform accordingly.
    void canvasSize(Vector2i size) {
      _canvasSize = size;
      setDisplayTransform();
    }

    /**
     * Get the display modes supported by the system.
     */
    auto supportedDisplayModes() {
      struct Range {
        private int _idx, _max;
        private ALLEGRO_DISPLAY_MODE _mode;
        this(int max) { _max = max; }

        @property bool empty() { return _idx == _max; }
        @property void popFront() { ++_idx; }

        @property auto front() {
          al_get_display_mode(_idx, &_mode);
          return _mode;
        }
      }

      return Range(al_get_num_display_modes);
    }

    auto ref color() { return _color; }
  }

  void clear() {
    al_clear_to_color(_color);
  }

  void flip() {
    al_flip_display();
  }

  private:
  void setDisplayTransform() {
    float scaleX = cast(float) displaySize.x / canvasSize.x;
    float scaleY = cast(float) displaySize.y / canvasSize.y;
    float scale = min(scaleX, scaleY);
    al_identity_transform(&_transform);
    al_scale_transform(&_transform, scale, scale);
  }
}
