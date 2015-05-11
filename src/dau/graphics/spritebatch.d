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

  void draw(T)(Bitmap bmp, Transform!T trans, Rect2 region, int depth = 0) {
    Entry entry;
    entry.bmp = bmp;
    entry.region = region;
    entry.tranform = trans;
    entry.depth = depth;
    _sprites.insert(entry);
  }

  void render(Camera camera) {
    // use camera transform, store previous transform
    ALLEGRO_TRANSFORM origTrans, baseTrans, entryTrans;
    /* TODO: needed?
    int x, y, w, h; // prev clipping rect
    al_get_clipping_rectangle(&x, &y, &w, &h);
    */
    al_copy_transform(&origTrans, al_get_current_transform());
    al_copy_transform(&baseTrans, &origTrans); // start with the current transform
    al_compose_transform(&baseTrans, camera.transform); // compose with the camera transform

    foreach(entry ; _sprites) {
      al_copy_transform(&entryTrans, &baseTrans);
      al_compose_transform(&entryTrans, entry.transform.transform);
      al_use_transform(&entryTrans);
      entry.bmp.drawRegion(entry.region);
    }

    al_use_transform(&origTrans); // restore old transform
    //al_set_clipping_rectangle(x, y, w, h); TODO: needed?
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
