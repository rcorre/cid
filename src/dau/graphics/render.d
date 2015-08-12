module dau.graphics.render;

import std.variant;
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
    alias Store = RedBlackTree!(Batch, (a,b) => a.depth < b.depth, true);
    Store _batches;
  }

  this() {
    _batches = new Store;
  }

  void render() {
    ALLEGRO_TRANSFORM origTrans;
    al_copy_transform(&origTrans, al_get_current_transform());

    al_hold_bitmap_drawing(true);
    foreach(batch ; _batches) {
      batch.flip(origTrans);
    }
    al_hold_bitmap_drawing(false);

    al_use_transform(&origTrans); // restore old transform
    _batches.clear();
  }

  void draw(SpriteBatch batch) { _batches.insert(Batch(batch)); }
  void draw(TextBatch batch)   { _batches.insert(Batch(batch)); }

  private:
  struct Batch {
    Algebraic!(SpriteBatch, TextBatch) _batch;

    this(T)(T batch) {
      _batch = batch;
    }

    auto depth() inout {
      // This no longer works with DMD 2.068,
      // But my approach here is hacky anyways.
      //return _batch.visit!((SpriteBatch b) => b.depth,
      //                     (TextBatch   b) => b.depth);
      return (_batch.type == typeid(SpriteBatch)) ?
        _batch.get!SpriteBatch.depth :
        _batch.get!TextBatch.depth;
    }

    void flip(ALLEGRO_TRANSFORM origTrans) {
      _batch.visit!((SpriteBatch b) => b.flip(origTrans),
                    (TextBatch   b) => b.flip(origTrans));
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

  private void flip(ALLEGRO_TRANSFORM origTrans) {
    ALLEGRO_TRANSFORM curTrans;
    al_copy_transform(&curTrans, &origTrans);

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

struct Text {
  bool            centered;
  Color           color = Color.black;
  string          text;
  Transform!float transform;
}

struct TextBatch {
  Font       font;
  int        depth;
  Array!Text texts;

  /**
   * Create a batch for drawing text with the same font and depth.
   *
   * Params:
   *  bitmap = bitmap to use as a sprite sheet
   *  depth = sprite layer; more positive means 'higher'
   */
  this(Font font, int depth) {
    this.font = font;
    this.depth  = depth;
  }

  /**
   * Insert a single sprite into the batch to be drawn this frame.
   *
   * Params:
   *  text = text to draw with this batch's font.
   */
  void opCatAssign(Text text) {
    texts.insert(text);
  }

  /**
   * Insert a range of text objects into the batch to be drawn this frame.
   *
   * Params:
   *  text = a range of text objects to draw with this batch's font.
   */
  void opCatAssign(R)(R r) if (isInputRange!R && is(ElementType!R == Text)) {
    texts.insert(r);
  }

  private void flip(ALLEGRO_TRANSFORM origTrans) {
    ALLEGRO_TRANSFORM curTrans;
    al_copy_transform(&curTrans, &origTrans);

    foreach(text ; texts) {
      // start with the original transform
      al_copy_transform(&curTrans, &origTrans);

      if (text.centered) {
        auto w = font.widthOf(text.text);
        auto h = font.heightOf(text.text);

        // translate by half the width and length to center the text
        al_translate_transform(&curTrans, -w / 2, -h / 2);
      }

      // compose with the transform for this individual text
      al_compose_transform(&curTrans, text.transform.transform);

      al_use_transform(&curTrans);

      font.draw(text.text, text.color);
    }
  }
}
