/**
 * Provides types and logic for batched drawing of graphics primitives.
 */
module cid.graphics.primitive;

import std.container : Array;
import std.range     : isInputRange, ElementType;

import allegro5.allegro;
import allegro5.allegro_primitives;

import cid.geometry;
import cid.graphics.blend;
import cid.graphics.color;

struct RectPrimitive {
  Rect2f   rect;
  bool     centered;
  bool     filled;
  float    thickness = 1f;
  Vector2f roundness = Vector2f.zero;
  Color    color     = Color.white;
}

struct PrimitiveBatch {
  int                 depth;
  Array!RectPrimitive prims;
  Blender             blender;

  /**
   * Create a batch for drawing graphics primitives at a given depth.
   *
   * Params:
   *  depth = sprite layer; more positive means 'higher'
   */
  this(int depth) {
    this.depth = depth;
  }

  /**
   * Insert a single primitive into the batch to be drawn this frame.
   *
   * Params:
   *  prim = primitive to draw with this batch.
   */
  void opCatAssign(RectPrimitive prim) {
    prims.insert(prim);
  }

  /**
   * Insert a range of primitives into the batch to be drawn this frame.
   *
   * Params:
   *  r = a range of primitives to draw with this batch.
   */
  void opCatAssign(R)(R r)
    if (isInputRange!R && is(ElementType!R == RectPrimitive))
  {
    prims.insert(r);
  }

  package void flip(ALLEGRO_TRANSFORM origTrans) {
    foreach(prim ; prims) {
      if (prim.filled) {
        al_draw_filled_rounded_rectangle(
            prim.rect.x, prim.rect.y,           // x1, y1
            prim.rect.right, prim.rect.bottom,  // x2, y2
            prim.roundness.x, prim.roundness.y, // rx, ry
            prim.color);                        // color
      }
      else {
        al_draw_rounded_rectangle(
            prim.rect.x, prim.rect.y,           // x1, y1
            prim.rect.right, prim.rect.bottom,  // x2, y2
            prim.roundness.x, prim.roundness.y, // rx, ry
            prim.color,                         // color
            prim.thickness);                    // thickness
      }
    }
  }
}
