module dau.graphics.render;

import std.range     : isInputRange, ElementType;
import std.typecons  : Proxy;
import std.typetuple : TypeTuple;
import std.container : Array, RedBlackTree;
import dau.allegro;
import dau.geometry;
import dau.graphics.font;
import dau.graphics.color;
import dau.graphics.camera;
import dau.graphics.bitmap;

class Renderer {
  private {
    // true indicates: allow duplicates (entries at same depth)
    alias Store = RedBlackTree!(SpriteBatch, (a,b) => a.depth < b.depth, true);
    Store _batches;
  }

  this() {
    _batches = new Store;
  }

  void render() {
    ALLEGRO_TRANSFORM origTrans;
    al_copy_transform(&origTrans, al_get_current_transform());

    foreach(batch ; _batches) {
      al_hold_bitmap_drawing(true);
      flipBatch(batch, origTrans);
      al_hold_bitmap_drawing(false);
    }

    al_use_transform(&origTrans); // restore old transform
    _batches.clear();
  }

  void draw(SpriteBatch batch) {
    _batches.insert(batch);
  }

  private:
  void flipBatch(SpriteBatch batch, ALLEGRO_TRANSFORM origTrans) {
    ALLEGRO_TRANSFORM curTrans;
    al_copy_transform(&curTrans, &origTrans);

    foreach(sprite ; batch.sprites) {
      // start with the original transform
      al_copy_transform(&curTrans, &origTrans);

      if (sprite.centered) {
        // translate by half the width and length to center the sprite
        al_translate_transform(&curTrans,
            -sprite.region.width / 2, -sprite.region.height / 2);
      }

      // compose with the transform for this individual sprite
      al_compose_transform(&curTrans, sprite.transform.transform);

      al_use_transform(&curTrans);

      batch.bitmap.drawRegion(sprite.region, sprite.color, sprite.flip);
    }
  }
}

struct Sprite {
  Rect2i          region;
  bool            centered;
  Color           color = Color.white;
  Bitmap.Flip     flip;
  Transform!float transform;
}

struct SpriteBatch {
  Bitmap       bitmap;
  int          depth;
  Array!Sprite sprites;

  /**
   * Create a batch for drawing sprites with the same bitmap and depth.
   *
   * Params:
   *  bitmap = bitmap to use as a sprite sheet
   *  depth = sprite layer; more positive means 'higher'
   */
  this(Bitmap bitmap, int depth) {
    this.bitmap = bitmap;
    this.depth  = depth;
  }

  /**
   * Insert a single sprite into the batch to be drawn this frame.
   *
   * Params:
   *  sprite = sprite to draw with this batch's bitmap.
   */
  void opCatAssign(Sprite sprite) {
    sprites.insert(sprite);
  }

  /**
   * Insert a range of sprites into the batch to be drawn this frame.
   *
   * Params:
   *  sprites = a range of sprites to draw with this batch's bitmap.
   */
  void opCatAssign(R)(R r) if (isInputRange!R && is(ElementType!R == Sprite)) {
    sprites.insert(r);
  }
}
