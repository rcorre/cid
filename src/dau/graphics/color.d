module dau.graphics.color;

import std.conv      : to;
import std.array     : array;
import std.string    : format, strip;
import std.algorithm : splitter, map;
import jsonizer;
import dau.allegro;
import dau.util.math;

struct Color {
  mixin JsonizeMe;

  ALLEGRO_COLOR _color;
  alias _color this;

  /**
   * Construct a color from a set of floats ranging from 0.0 to 1.0.
   * Params:
   *  r = red
   *  g = green
   *  b = blue
   *  a = alpha
   */
  @jsonize this(float r, float g, float b, float a = 1.0f) {
    _color = ALLEGRO_COLOR(r, g, b, a);
  }

  /// parse color from string of form "r,g,b" or "r,g,b,a" with values given as floats
  @jsonize this(string csv) {
    auto vals = csv.splitter(",").map!(x => x.strip.to!float).array;
    if (vals.length == 3) {
      this(vals[0], vals[1], vals[2]);
    }
    else if (vals.length == 4) {
      this(vals[0], vals[1], vals[2], vals[3]);
    }
    else {
      assert(0, "failed to parse color from %s (%d entries)".format(csv, vals.length));
    }
  }

  /**
   * Construct a color from a set of unsigned bytes ranging from 0 to 255.
   * Params:
   *  r = red
   *  g = green
   *  b = blue
   *  a = alpha
   */
  this(ubyte r, ubyte g, ubyte b, ubyte a = 255u) {
    this(r / 255f, g / 255f, b / 255f, a / 255f);
  }

  /**
   * Wrap an ALLEGRO_COLOR struct.
   * Params:
   *  color = an ALLEGRO_COLOR struct
   */
  this(ALLEGRO_COLOR color) {
    _color = color;
  }

  static @property {
    Color white() { return Color(1f  , 1f  , 1f  , 1f); }
    Color gray () { return Color(0.5 , 0.5 , 0.5 , 1f); }
    Color black() { return Color(0f  , 0f  , 0f  , 1f); }
    Color red  () { return Color(1f  , 0f  , 0f  , 1f); }
    Color green() { return Color(0f  , 1f  , 0f  , 1f); }
    Color blue () { return Color(0f  , 0f  , 1f  , 1f); }
    Color clear() { return Color(0f  , 0f  , 0f  , 0f); }
  }
}

Color lerp(Color start, Color end, float factor) {
  auto r = dau.util.math.lerp(start.r, end.r, factor);
  auto g = dau.util.math.lerp(start.g, end.g, factor);
  auto b = dau.util.math.lerp(start.b, end.b, factor);
  auto a = dau.util.math.lerp(start.a, end.a, factor);
  return Color(r, g, b, a);
}

Color lerp(Color[] colors, float factor) {
  if (colors.length == 2) {
    return lerp(colors[0], colors[1], factor);
  }

  float colorTime = 1.0 / (colors.length - 1); // time for each color pair
  int idx = roundDown(factor * (colors.length - 1));
  if (idx < 0) {  // before first color
    return colors[0];  // return first
  }
  else if (idx >= colors.length - 1) {  // past last color
    return colors[$ - 1];  // return last
  }
  factor = (factor % colorTime) / colorTime;
  return lerp(colors[idx], colors[idx + 1], factor);
}

unittest {
  bool approxEqual(Color c1, Color c2) {
    import std.math : approxEqual;
    return c1.r.approxEqual(c2.r) &&
      c1.g.approxEqual(c2.g) &&
      c1.b.approxEqual(c2.b) &&
      c1.a.approxEqual(c2.a);
  }

  // float color with implied alpha
  auto c1 = Color(0.5, 1, 0.3);
  assert(approxEqual(c1, Color(0.5, 1, 0.3, 1)));

  // float color with specified alpha
  auto c2 = Color(0, 0, 0, 0.5);
  assert(approxEqual(c2, Color(0, 0, 0, 0.5)));

  // unsigned color with implied alpha
  auto c3 = Color(100, 255, 0);
  assert(approxEqual(c3, Color(100 / 255f, 1, 0, 1)));

  // unsigned color with specified alpha
  auto c4 = Color(0, 0, 255, 127);
  assert(approxEqual(c4, Color(0, 0, 1, 127 / 255f)));

  auto c5 = Color.black.lerp(Color.white, 0.5);
  assert(c5 == Color(0.5, 0.5, 0.5, 1));

  assert(lerp([Color.black, Color.white, Color.red], 0) == Color.black);
  assert(lerp([Color.black, Color.white, Color.red], 0.1) == Color(0.2, 0.2, 0.2));
  assert(lerp([Color.black, Color.white, Color.red], 0.5) == Color.white);
  assert(approxEqual(lerp([Color.black, Color.white, Color.red], 0.6), Color(1, 0.8, 0.8)));
  assert(approxEqual(lerp([Color.black, Color.white, Color.red], 1), Color.red));

  // parsing from strings
  assert(approxEqual(Color("1,0,1")              , Color(1, 0, 1.0)));
  assert(approxEqual(Color("1.0,0.5,0.2")        , Color(1, 0.5, 0.2)));
  assert(approxEqual(Color("1.0, 0.5, 0.2")      , Color(1, 0.5, 0.2)));
  assert(approxEqual(Color("1.0, 0.5, 0.2, 0.7") , Color(1, 0.5, 0.2, 0.7)));
  assert(approxEqual(Color("1.0,0.5,0.2,0.7")    , Color(1, 0.5, 0.2, 0.7)));
}

/// Colors can be parsed from JSON
unittest {
  auto jstr = q{
    [
      {"r": 1.0, "g": 0.5, "b": 0.0},
      "1.0, 0.5, 0.0",
      "1.0, 0.5, 0.0, 0.5"
    ]
  };

  auto colors = jstr.fromJSONString!(Color[]);
  assert(colors[0] == Color(1.0, 0.5, 0.0));
  assert(colors[1] == Color(1.0, 0.5, 0.0));
  assert(colors[2] == Color(1.0, 0.5, 0.0, 0.5));
}
