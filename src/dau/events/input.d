module dau.events.input;

import std.conv      : to;
import std.traits    : EnumMembers;
import std.string    : toLower;
import std.algorithm : map;
import std.container : Array;
import dau.allegro;
import dau.events.keycodes;
import jsonizer;

package {
  enum Direction : uint { up, down, left, right }
  enum nDirections = EnumMembers!Direction.length;
}

struct ControlScheme {
  @jsonize {
    ButtonMap[string] buttons;
    AxisMap[string]   axes;
  }
}

struct ButtonMap {
  Array!int keys;
  Array!int buttons;

  @jsonize
  this(string[] keys, int[] buttons) {
    this.buttons = buttons;
    this.keys = keys.map!(x => x.toLower.to!KeyCode.to!int);
  }
}

struct AxisMap {
  struct SubAxis {
    int stick;
    int axis;
  }

  SubAxis          xAxis;
  SubAxis          yAxis;
  int[nDirections] keys;

  @jsonize
  this(string[string] keys, SubAxis[string] axes) {
    foreach(direction, name ; keys) {
      this.keys[direction.to!Direction] = name.to!KeyCode;
    }

    this.xAxis = axes["x"];
    this.yAxis = axes["y"];
  }
}
