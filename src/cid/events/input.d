module cid.events.input;

import std.conv      : to;
import std.array     : array;
import std.traits    : EnumMembers;
import std.string    : toLower;
import std.algorithm : map;
import cid.allegro;
import cid.events.keycodes;
import jsonizer;

struct ControlScheme {
  mixin JsonizeMe;

  @jsonize {
    ButtonMap[string] buttons;
    AxisMap[string]   axes;
  }
}

struct ButtonMap {
  mixin JsonizeMe;

  KeyCode[] keys;
  int[] buttons;

  @jsonize
  this(string[] keys, int[] buttons) {
    this.buttons = buttons;
    this.keys = keys.map!(x => x.toLower.to!KeyCode).array;
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

  SubAxis xAxis;
  SubAxis yAxis;

  KeyCode upKey;
  KeyCode downKey;
  KeyCode leftKey;
  KeyCode rightKey;

  @jsonize
  this(string[string] keys, SubAxis[string] axes) {
    this.upKey    = keys["up"   ].to!KeyCode;
    this.downKey  = keys["down" ].to!KeyCode;
    this.leftKey  = keys["left" ].to!KeyCode;
    this.rightKey = keys["right"].to!KeyCode;

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
          "x": { "stick": 1, "axis": 0 },
          "y": { "stick": 2, "axis": 3 }
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

  assert(controls.axes["move"].upKey    == ALLEGRO_KEY_W);
  assert(controls.axes["move"].downKey  == ALLEGRO_KEY_S);
  assert(controls.axes["move"].leftKey  == ALLEGRO_KEY_A);
  assert(controls.axes["move"].rightKey == ALLEGRO_KEY_D);

  assert(controls.axes["move"].xAxis.stick == 1);
  assert(controls.axes["move"].yAxis.stick == 2);
  assert(controls.axes["move"].xAxis.axis  == 0);
  assert(controls.axes["move"].yAxis.axis  == 3);
}
