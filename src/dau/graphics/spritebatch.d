module dau.graphics.spritebatch;

import std.container : RedBlackTree;
import dau.allegro;
import dau.geometry;
import dau.graphics.camera;
import dau.graphics.bitmap;

// TODO: group textures and use al_hold_bitmap_drawing
class SpriteBatch {
  this() {
    _sprites = new SpriteStore;
  }

  void draw(T)(Bitmap bmp, Transform!T trans, Rect2i region, int depth = 0) {
    Entry entry;
    entry.bmp = bmp;
    entry.region = region;
    entry.transform = trans;
    entry.depth = depth;
    _sprites.insert(entry);
  }

  void render() {
    ALLEGRO_TRANSFORM origTrans, curTrans;
    al_copy_transform(&origTrans, al_get_current_transform());

    foreach(entry ; _sprites) {
      al_copy_transform(&curTrans, &origTrans);
      al_compose_transform(&curTrans, entry.transform.transform);
      al_use_transform(&curTrans);
      entry.bmp.drawRegion(entry.region);
    }

    al_use_transform(&origTrans); // restore old transform
    _sprites.clear();
  }

  private:
  struct Entry {
    Bitmap bmp;
    Rect2i region;
    Transform!float transform;
    int depth;
  }

  // true indicates: allow duplicates
  alias SpriteStore = RedBlackTree!(Entry, (a,b) => a.depth < b.depth, true);
  SpriteStore _sprites;
}
