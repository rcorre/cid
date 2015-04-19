module dau.state;

import std.stdio, std.path, std.conv, std.string;
import std.container : SList;
import dau.input;
import dau.graphics.spritebatch;

/// Generic behavioral state
class State(T) {
  /// called only once before the state is first updated
  void start(T object) { }
  /// called only once when the state is removed
  void end(T object) { }
  /// called once whenever the state becomes active (pushed to top or state above is popped)
  void enter(T object) { }
  /// called once whenever the state becomes inactive (popped or new state pushed above)
  void exit(T object) { }
  /// called every frame before drawing
  void update(T object, float time, InputManager input) { }
  /// called every frame between screen clear and screen flip
  void draw(T object, SpriteBatch sb) { }

  private bool _active, _started;
}

/// Manages a LIFO stack of states which determine how and instance `T` behaves.
class StateStack(T) {
  this(T obj) {
    _obj = obj;
  }

  @property {
    /// The state at the top of the stack.
    auto currentState() { return _stateStack.front; }
    /// True if no states exist on the stack.
    bool empty() { return _stateStack.empty; }
  }

  /// Place a new state on the state stack.
  void push(State!T state) {
    _stateStack.insertFront(state);
    debug(StateTrace) { printStateTrace(); }
  }

  /// Remove the current state.
  void pop() {
    currentState.exit(_obj);
    currentState.end(_obj);
    _stateStack.removeFront;
    _prevState = null;
    debug(StateTrace) { printStateTrace(); }
  }

  /// Pop the current state (if there is a current state) and push a new state.
  void replace(State!T state) {
    if (!_stateStack.empty) {
      pop();
    }
    push(state);
  }

  /// Call `update` on the active state.
  void update(float time, InputManager input) {
    activateTop();
    currentState.update(_obj, time, input);
  }

  /// Call `draw` on the active state.
  void draw(SpriteBatch sb) {
    activateTop();
    currentState.draw(_obj, sb);
  }

  /// Print out the names of all states on the stack. Useful for debugging behavior.
  void printStateTrace() {
    foreach(state ; _stateStack) {
      write(typeid(state).to!string.extension.chompPrefix("."), " | ");
    }
    writeln;
  }

  private:
  SList!(State!T) _stateStack;
  State!T _prevState;
  T _obj;

  void activateTop() {
    while (!currentState._active) { // call enter() is state is returning to activity
      currentState._active = true;
      if (_prevState !is null) {
        _prevState._active = false;
        _prevState.exit(_obj);
      }
      _prevState = currentState;
      if (!currentState._started) {
        currentState._started = true;
        currentState.start(_obj);
      }
      if (currentState._started) { // state might have changed after start
        currentState.enter(_obj);
      }
    }
  }
}
