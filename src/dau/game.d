module dau.game;

import std.algorithm;
import dau.setup;
import dau.allegro;
import dau.state;
import dau.input;
import dau.system;
import dau.gui.manager;
import dau.graphics;

class Game {
  this(System[] systems, GameSettings settings) {
    _inputManager    = new InputManager;
    _stateStack      = new StateStack!Game(this);
  }

  @property {
    auto states()   { return _stateStack; }
    auto input()    { return _inputManager; }
    auto camera()   { return _camera; }
    auto deltaTime() { return _deltaTime; }
  }

  /// called every frame before drawing
  void update(float time) {
    _deltaTime = time;
    _inputManager.update(time);
    _stateStack.run();
    foreach(sys ; _systems) {
      if (sys.active) {
        sys.update(time, input);
      }
    }
  }

  /// called every frame between screen clear and screen flip
  void draw() {
    al_clear_to_color(_backgroundColor);
    al_flip_display();
  }

  S getSystem(S)() {
    auto res = _systems.map!(x => cast(S) x).find!(x => x !is null);
    assert(!res.empty, "failed to find system " ~ S.stringof);
    return res.front;
  }

  void enableSystem(S)() {
    getSystem!S().active = true;
  }

  void disableSystem(S)() {
    getSystem!S.active = false;
  }

  private:
  StateStack!Game _stateStack;
  InputManager    _inputManager;
  Camera          _camera;
  System[]        _systems;
  Color           _backgroundColor;
  float           _deltaTime;

  private:
  bool _started;
}
