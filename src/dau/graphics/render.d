module dau.graphics.render;

import std.range     : only, isInputRange, ElementType;
import std.typecons  : Proxy;
import std.typetuple : TypeTuple;
import std.container : SList, RedBlackTree;
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
      batch.draw(origTrans);
      al_hold_bitmap_drawing(false);
    }

    al_use_transform(&origTrans); // restore old transform
    _batches.clear();
  }

  void draw(Sprite sprite, Bitmap bmp, int depth = 0) {
    draw(sprite.only, bmp, depth);
  }

  void draw(R)(R sprites, Bitmap bmp, int depth = 0)
    if (isInputRange!R && is(ElementType!R == Sprite))
  {
    SpriteBatch sb;

    sb.depth   = depth;
    sb.bitmap  = bmp;
    sb.sprites.insert(sprites);

    _batches.insert(sb);
  }

  struct SpriteBatch {
    int          depth;
    Bitmap       bitmap;
    SList!Sprite sprites;

    void draw(ALLEGRO_TRANSFORM origTrans) {
      ALLEGRO_TRANSFORM curTrans;

      foreach(sprite ; sprites) {
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

        bitmap.drawRegion(sprite.region, sprite.color, sprite.flip);
      }
    }
  }
}

struct Sprite {
  Rect2i          region;
  bool            centered;
  Color           color;
  Bitmap.Flip     flip;
  Transform!float transform;
}
