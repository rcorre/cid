module dau.graphics.spritebatch;

import std.container : RedBlackTree;
import dau.allegro;
import dau.geometry;
import dau.graphics.camera;
import dau.graphics.sprite;

// TODO: group textures and use al_hold_bitmap_drawing
class SpriteBatch {
  this() {
    _sprites = new SpriteStore;
  }

  void draw(T)(Sprite sprite) {
    _sprites.insert(sprite);
  }

  void render() {
    ALLEGRO_TRANSFORM origTrans, curTrans;
    al_copy_transform(&origTrans, al_get_current_transform());

    foreach(sprite ; _sprites) {
      al_copy_transform(&curTrans, &origTrans);
      al_compose_transform(&curTrans, sprite.transform.transform);
      al_use_transform(&curTrans);
      sprite.bmp.drawRegion(sprite.region, sprite.color, sprite.flip);
    }

    al_use_transform(&origTrans); // restore old transform
    _sprites.clear();
  }

  private:

  // true indicates: allow duplicates
  alias SpriteStore = RedBlackTree!(Sprite, (a,b) => a.depth < b.depth, true);
  SpriteStore _sprites;
}
