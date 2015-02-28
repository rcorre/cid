module dau.scene;

import std.algorithm;
import dau.setup;
import dau.allegro;
import dau.state;
import dau.input;
import dau.entity;
import dau.system;
import dau.gui.manager;
import dau.graphics.all;

private IScene _currentScene;

void setScene(T)(Scene!T newScene) {
  if (_currentScene !is null) {
    _currentScene.exit();
  }
  newScene.enter();
  _currentScene = newScene;
}

@property auto currentScene() { return _currentScene; }

class Scene(T) : IScene {
  this(System!(T)[] systems, Sprite[string] cursorSpriteMap, Color bgColor = Color.black) {
    _inputManager  = new InputManager;
    _entityManager = new EntityManager;
    _spriteBatch   = new SpriteBatch;
    _guiManager    = new GUIManager;
    _camera        = new Camera(Settings.screenW, Settings.screenH);
    _systems       = systems;
    _stateMachine  = new StateMachine!T(cast(T) this);
    _cursorManager = new CursorManager(cursorSpriteMap);
    _backgroundColor = bgColor;
  }

  @property {
    auto entities() { return _entityManager; }
    auto states()   { return _stateMachine; }
    auto input()    { return _inputManager; }
    auto cursor()   { return _cursorManager; }
    auto camera()   { return _camera; }
    auto gui()      { return _guiManager; }
  }

  override {
    void enter() { }
    void exit()  { }
    /// called every frame before drawing
    void update(float time) {
      _inputManager.update(time);
      _entityManager.updateEntities(time);
      _stateMachine.update(time, _inputManager);
      _guiManager.update(time, input);
      _cursorManager.update(time);
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
      _stateMachine.draw(_spriteBatch);
      _spriteBatch.render(camera);
      _guiManager.draw(); // gui draws over state & entities
      _cursorManager.draw(input.mousePos);
      al_flip_display();
    }
  }

  S getSystem(S)() {
    auto res = _systems.map!(x => cast(S) x).find!(x => x !is null);
    assert(!res.empty, "failed to find system " ~ S.stringof ~ " in scene " ~ T.stringof);
    return res.front;
  }

  void enableSystem(S)() {
    getSystem!S().active = true;
  }

  void disableSystem(S)() {
    getSystem!S.active = false;
  }

  private:
  EntityManager  _entityManager;
  GUIManager     _guiManager;
  StateMachine!T _stateMachine;
  InputManager   _inputManager;
  CursorManager  _cursorManager;
  SpriteBatch    _spriteBatch;
  Camera         _camera;
  System!(T)[]   _systems;
  Color          _backgroundColor;

  private:
  bool _started;
}

interface IScene {
  void enter();
  void exit();
  void update(float time);
  void draw();
}
