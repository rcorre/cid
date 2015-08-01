module dau.events.input;

import std.conv      : to;
import std.array     : array;
import std.traits    : EnumMembers;
import std.string    : toLower;
import std.algorithm : map;
import dau.allegro;
import dau.events.keycodes;
import jsonizer;

package {
  enum Direction : uint { up, down, left, right }
  enum nDirections = EnumMembers!Direction.length;
}

struct ControlScheme {
  mixin JsonizeMe;

  @jsonize {
    ButtonMap[string] buttons;
    AxisMap[string]   axes;
  }
}

struct ButtonMap {
  mixin JsonizeMe;

  int[] keys;
  int[] buttons;

  @jsonize
  this(string[] keys, int[] buttons) {
    this.buttons = buttons;
    this.keys = keys.map!(x => x.toLower.to!KeyCode.to!int).array;
  }
}

struct AxisMap {
  mixin JsonizeMe;

  struct SubAxis {
    mixin JsonizeMe;

    @jsonize {
      int stick;
      int axis;
    }
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

unittest {
  import std.algorithm : equal;

  auto json = `
  {
    "buttons": {
      "confirm": {
        "keys": [ "j", "enter", "space" ],
          "buttons": [ 1, 2 ]
      },
        "cancel": {
          "keys": [ "k", "escape" ],
          "buttons": [ 3, 4 ]
        }
    },
    "axes": {
      "move": {
        "keys": {
          "up"   : "w",
          "down" : "s",
          "left" : "a",
          "right": "d"
        },
        "axes": {
          "x": { "stick": 0, "axis": 0 },
          "y": { "stick": 0, "axis": 1 }
        }
      }
    }
  }`;

  auto controls = json.fromJSONString!ControlScheme;

  assert(controls.buttons["confirm"].keys[].equal(
    [ ALLEGRO_KEY_J, ALLEGRO_KEY_ENTER, ALLEGRO_KEY_SPACE ]));

  assert(controls.buttons["confirm"].buttons[].equal([ 1, 2]));

  assert(controls.buttons["cancel"].keys[].equal(
    [ ALLEGRO_KEY_K, ALLEGRO_KEY_ESCAPE ]));

  assert(controls.buttons["cancel"].buttons[].equal([ 3, 4]));
}
