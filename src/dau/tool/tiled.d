module dau.tool.tiled;

import std.conv;
import std.range;
import std.file;
import std.algorithm;
import jsonizer;
import dau.engine;
import dau.graphics;

auto loadTiledMap(string path) {
  assert(path.exists, "no map file found at " ~ path);
  return readJSON!MapData(path);
}

class TileData {
  int x, y;
  int row, col;
  int tilesetIdx;
  string tilesetName;
  string objectName;
  string objectType;
  string[string] properties;
}

/// Flags set by Tiled in the guid field.
enum TileFlag {
  flipHorizontal = 0x80000000,
  flipVertical   = 0x40000000,
  flipDiagonal   = 0x20000000,
  all            = flipHorizontal | flipVertical | flipDiagonal,
}

class MapData {
  mixin JsonizeMe;

  enum Orientation {
    orthogonal,
    isometric
  }

  @jsonize(JsonizeOptional.no) {
    int width, height;         // in number of tiles
    int tilewidth, tileheight; // in pixels
    Orientation orientation;
    string[string] properties;
    MapLayer[] layers;
    TileSet[] tilesets;
  }

  @jsonize(JsonizeOptional.yes) {
    float opacity;
  }

  TileRange layerTileData(int idx) {
    assert(idx >= 0 && idx < layers.length, "no layer at idx " ~ idx.to!string);
    return TileRange(layers[idx], tilesets);
  }

  TileRange layerTileData(string name) {
    auto idx = layers.countUntil!(x => name == x.name);
    assert(idx >= 0, "no layer named " ~ name);
    return layerTileData(idx.to!int);
  }

  struct TileRange {
    this(MapLayer layer, TileSet[] tilesets) {
      _layer = layer;
      _tilesets = tilesets;
    }

    @property {
      bool empty() {
        return _idx == (isObjectLayer ? _layer.objects.length : _layer.data.length);
      }

      bool isObjectLayer() {
        return _layer.type == MapLayer.Type.objectgroup;
      }

      int numTiles() {
        return cast(int) (isObjectLayer ? _layer.objects.length : _layer.data.length);
      }

      TileData front() {
        // TODO: encode flip information
        auto data = new TileData;
        if (isObjectLayer) {
          auto obj = _layer.objects[_idx];
          // Tiled encodes flipped state in top 3 bits -- clear these to get the actual gid
          auto gid = obj.gid & ~(TileFlag.all);
          auto tileset = gidToTileset(gid);
          data.y = obj.y;
          data.x = obj.x;
          data.row = obj.y / tileset.tileheight - 1; // tiled is off by 1
          data.col = obj.x / tileset.tilewidth;
          data.tilesetIdx = obj.gid - tileset.firstgid;
          data.tilesetName = tileset.name;
          data.properties = obj.properties;
          data.objectName = obj.name;
          data.objectType = obj.type;
        }
        else {
          // Tiled encodes flipped state in top 3 bits -- clear these to get the actual gid
          auto gid = _layer.data[_idx] & (~TileFlag.all);
          auto tileset = gidToTileset(gid);
          data.row = _idx / _layer.width;
          data.col = _idx % _layer.width;
          data.tilesetIdx = gid - tileset.firstgid;
          data.tilesetName = tileset.name;
          data.properties = tileset.tileproperties[data.tilesetIdx.to!string];
        }
        return data;
      }
    }

    void popFront() {
      ++_idx;
    }

    private:
    MapLayer _layer;
    TileSet[] _tilesets;
    int _idx;

    TileSet gidToTileset(int gid) {
      if (gid == 0) { return null; }
      auto tileset = _tilesets.find!(x => x.firstgid <= gid);
      assert(!tileset.empty, "could not match gid " ~ to!string(gid));
      return tileset.front;
    }
  }
}

class MapLayer {
  enum Type {
    tilelayer,
    objectgroup
  }

  mixin JsonizeMe;

  @jsonize(JsonizeOptional.no) {
    int[] data;
    int width, height;
    string name;
    float opacity;
    Type type;
    bool visible;
    int x, y;
  }

  // These entries exist only on object layers
  @jsonize(JsonizeOptional.yes) {
    MapObject[] objects;
    string[string] properties;
  }
}

class MapObject {
  mixin JsonizeMe;
  @jsonize {
    int gid;
    int width, height;
    string name;
    string type;
    string[string] properties;
    bool visible;
    int x, y;
  }
}

class TileSet {
  mixin JsonizeMe;
  @jsonize {
    int firstgid;
    string image;
    string name;
    int tilewidth, tileheight;
    int imagewidth, imageheight;
    string[string] properties;
    string[string][string] tileproperties;
  }
}
