module dau.graphics.render;

import std.container : RedBlackTree;
import dau.allegro;
import dau.geometry;
import dau.graphics.camera;
import dau.graphics.color;
import dau.graphics.bitmap;

// TODO: group textures and use al_hold_bitmap_drawing
class Renderer {
  this() {
    _entries = new EntryStore;
  }

  void draw(RenderInfo info) {
    _entries.insert(info);
  }

  void render() {
    ALLEGRO_TRANSFORM origTrans, curTrans;
    al_copy_transform(&origTrans, al_get_current_transform());

    foreach(entry ; _entries) {
      al_copy_transform(&curTrans, &origTrans);

      if (entry.centered) {
        al_translate_transform(&curTrans,
            -entry.region.width / 2, -entry.region.height / 2);
      }

      al_compose_transform(&curTrans, entry.transform.transform);
      al_use_transform(&curTrans);

      entry.bmp.drawRegion(entry.region, entry.color, entry.flip);
    }

    al_use_transform(&origTrans); // restore old transform
    _entries.clear();
  }

  private:

  // true indicates: allow duplicates
  alias EntryStore = RedBlackTree!(RenderInfo, (a,b) => a.depth < b.depth, true);
  EntryStore _entries;
}

/// Encompasses information needed to render a bitmap to the screen
struct RenderInfo {
  Bitmap           bmp;
  Rect2i           region;
  Transform!float  transform;
  int              depth;
  Bitmap.Flip      flip;
  Color            color = Color.white;
  bool             centered;
}
