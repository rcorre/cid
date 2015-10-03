module cid.graphics.render;

import std.variant;
import std.range     : isInputRange, ElementType;
import std.typecons  : Proxy;
import std.typetuple : TypeTuple;
import std.container : Array, RedBlackTree;
import cid.allegro;
import cid.geometry;
import cid.graphics.font;
import cid.graphics.blend;
import cid.graphics.color;
import cid.graphics.bitmap;
import cid.graphics.sprite;
import cid.graphics.text;
import cid.graphics.primitive;

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

    foreach(batch ; _batches) {
      batch.flip(origTrans);
      al_use_transform(&origTrans); // restore old transform
    }

    _batches.clear();
  }

  void draw(SpriteBatch batch)    { _batches.insert(Batch(batch)); }
  void draw(TextBatch batch)      { _batches.insert(Batch(batch)); }
  void draw(PrimitiveBatch batch) { _batches.insert(Batch(batch)); }

  private:
  struct Batch {
    Algebraic!(SpriteBatch, TextBatch, PrimitiveBatch) _batch;

    this(T)(T batch) {
      _batch = batch;
    }

    auto depth() inout {
      // This no longer works with DMD 2.068,
      // But my approach here is hacky anyways.
      //return _batch.visit!((SpriteBatch b) => b.depth,
      //                     (TextBatch   b) => b.depth);
      auto t = _batch.type;
      if (t == typeid(SpriteBatch))    return _batch.get!SpriteBatch.depth;
      if (t == typeid(TextBatch))      return _batch.get!TextBatch.depth;
      if (t == typeid(PrimitiveBatch)) return _batch.get!PrimitiveBatch.depth;
      assert(0);
    }

    auto blender() {
      return _batch.visit!((SpriteBatch    b) => b.blender,
                           (TextBatch      b) => b.blender,
                           (PrimitiveBatch b) => b.blender);
    }

    void flip(ALLEGRO_TRANSFORM origTrans) {
      _batch.visit!((SpriteBatch    b) => b.flip(origTrans),
                    (TextBatch      b) => b.flip(origTrans),
                    (PrimitiveBatch b) => b.flip(origTrans));
    }
  }
}
