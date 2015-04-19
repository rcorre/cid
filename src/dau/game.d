module dau.game;

import std.algorithm;
import dau.setup;
import dau.allegro;
import dau.state;
import dau.input;
import dau.entity;
import dau.system;
import dau.gui.manager;
import dau.graphics.all;

class Game {
  /// TODO: think about ways to deprecate and avoid global state?
  static Game instance;

  static void start(System[] systems, GameSettings settings)
  {
    instance = new Game(systems, settings);
  }

  this(System[] systems, GameSettings settings) {
    _inputManager    = new InputManager;
    _entityManager   = new EntityManager;
    _spriteBatch     = new SpriteBatch;
    _guiManager      = new GUIManager;
    _camera          = new Camera(settings.screenWidth, settings.screenHeight);
    _systems         = systems;
    _stateStack      = new StateStack!Game(this);
    _backgroundColor = settings.bgColor;
  }

  @property {
    auto entities() { return _entityManager; }
    auto states()   { return _stateStack; }
    auto input()    { return _inputManager; }
    auto camera()   { return _camera; }
    auto gui()      { return _guiManager; }
  }

  /// called every frame before drawing
  void update(float time) {
    _inputManager.update(time);
    _entityManager.updateEntities(time);
    _stateStack.update(time, _inputManager);
    _guiManager.update(time, input);
    foreach(sys ; _systems) {
      if (sys.active) {
        sys.update(time, input);
      }
    }
  }

  /// called every frame between screen clear and screen flip
  void draw() {
    al_clear_to_color(_backgroundColor);
    _entityManager.drawEntities(_spriteBatch);
    _stateStack.draw(_spriteBatch);
    _spriteBatch.render(camera);
    _guiManager.draw(); // gui draws over state & entities
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
  EntityManager   _entityManager;
  GUIManager      _guiManager;
  StateStack!Game _stateStack;
  InputManager    _inputManager;
  SpriteBatch     _spriteBatch;
  Camera          _camera;
  System[]        _systems;
  Color           _backgroundColor;

  private:
  bool _started;
}

interface IScene {
  void enter();
  void exit();
  void update(float time);
  void draw();
}
