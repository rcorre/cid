/**
 * Generic state stack implementation.
 *
 * StateStack is most notably used to manage the flow of Game logic.
 * However, a StateStack could be attached to anything that needs stateful behavior.
 */
module dau.state;

import std.container : SList;
import dau.input;
import dau.graphics.spritebatch;

/// Generic behavioral state
class State(T) {
  /// Called only once before the state is first run
  void start(T object) { }
  /// Called only once when the state is removed
  void end(T object) { }
  /// Called once whenever the state becomes active (pushed to top or state above is popped)
  void enter(T object) { }
  /// Called once whenever the state becomes inactive (popped or new state pushed above)
  void exit(T object) { }
  /// Called every frame before drawing
  void run(T object) { }

  private bool _active, _started;
}

/// Manages a LIFO stack of states which determine how an instance of `T` behaves.
class StateStack(T) {
  this(T obj) {
    _obj = obj;
  }

  @property {
    /// The state at the top of the stack.
    auto current() { return _stack.front; }
    /// True if no states exist on the stack.
    bool empty() { return _stack.empty; }
  }

  /// Place a new state on the state stack.
  void push(State!T state) {
    _stack.insertFront(state);
  }

  /// Remove the current state.
  void pop() {
    auto state = current;
    _stack.removeFront;
    state.exit(_obj);
    state.end(_obj);
    _prevState = null;
  }

  /// Pop the current state, but assert that the current state is of the expected type.
  ///
  /// This is useful for validating that you are popping the state you expect you are popping
  /// Params:
  ///   Expected: Type of state you expect to pop from the top
  void pop(Expected)() {
    import std.format : format;
    assert(typeid(current) == typeid(Expected), 
        "expected to pop state %s, but found %s".format(typeid(current), typeid(Expected)));
    pop();
  }

  /// Pop the current state (if there is a current state) and push a new state.
  void replace(State!T state) {
    if (!_stack.empty) {
      pop();
    }
    push(state);
  }

  /// Call `run` on the active state.
  void run() {
    activateTop();
    current.run(_obj);
  }

  /// Return a string containing the name of each state on the stack, with the 'lowest' on the left
  string stackString() {
    import std.string : split, join;
    import std.algorithm : map;

    string getName(State!T state) { return state.classinfo.name.split(".")[$ - 1]; }
    return _stack[].map!(state => getName(state)).join(" | ");
  }

  private:
  SList!(State!T) _stack;
  State!T _prevState;
  T _obj;

  void activateTop() {
    // need to loop because start/enter may change the active state
    while (!current._active) {
      current._active = true;
      if (_prevState !is null) {
        _prevState._active = false;
        _prevState.exit(_obj);
      }
      _prevState = current;
      if (!current._started) {
        current._started = true;
        current.start(_obj);
      }
      if (current._started) { // state might have changed after start
        current.enter(_obj);
      }
    }
  }
}

version (unittest) {
  private {
    class Foo {
      string[] log;
      StateStack!Foo states;

      this() {
        states = new StateStack!Foo(this);
      }

      void check(string[] entries ...) {
        import std.format : format;
        assert(log == entries, "expected %s, got %s".format(entries, log));
        log = null;
      }
    }

    class LoggingState : State!Foo {
      override {
        void start (Foo foo) { foo.log ~= name ~ ".start"; }
        void end   (Foo foo) { foo.log ~= name ~ ".end";   }
        void enter (Foo foo) { foo.log ~= name ~ ".enter"; }
        void exit  (Foo foo) { foo.log ~= name ~ ".exit";  }
        void run   (Foo foo) { foo.log ~= name ~ ".run";   }
      }

      @property string name() { 
        import std.string : split;
        return this.classinfo.name.split(".")[$ - 1];
      }
    }

    class A : LoggingState { }

    class B : LoggingState { }

    // pushes states during enter/exit
    class D : LoggingState {
      override {
        void enter(Foo foo) { foo.states.push(new A); }
        void exit(Foo foo) { foo.states.push(new B); }
      }
    }

    // pops self during enter
    class E : LoggingState {
      override {
        void enter(Foo foo) { foo.states.push(new B); }
        void exit(Foo foo) { foo.states.push(new B); }
      }
    }
  }
}

// push, run, and pop single state
unittest {
  auto foo = new Foo;

  // just pushing shouldn't call anything
  foo.states.push(new A);
  foo.check();

  foo.states.run();
  foo.check("A.start", "A.enter", "A.run");
  foo.states.run();
  foo.check("A.run");

  foo.states.pop();
  foo.check("A.exit", "A.end");
}

// push multiple states
unittest {
  auto foo = new Foo;

  foo.states.push(new A);
  foo.states.run(); // A
  foo.check("A.start", "A.enter", "A.run");

  foo.states.push(new B);
  foo.check();
  foo.states.run(); // A B
  foo.check("A.exit", "B.start", "B.enter", "B.run");
}

// push state during start
unittest {
  class C : LoggingState {
    override void start(Foo foo) { super.start(foo); foo.states.push(new A); }
  }

  auto foo = new Foo;

  foo.states.push(new C);
  foo.states.run();
  // enter never runs, skipped during start
  foo.check("C.start", "C.exit", "A.start", "A.enter", "A.run");
  foo.states.pop();
  foo.check("A.exit", "A.end");
  // already started, won't start again
  foo.states.run();
  foo.check("C.enter", "C.run");
}

// push state during enter
unittest {
  class C : LoggingState {
    override void enter(Foo foo) { super.enter(foo); foo.states.push(new A); }
  }

  auto foo = new Foo;

  foo.states.push(new C);
  foo.states.run();
  foo.check("C.start", "C.enter", "C.exit", "A.start", "A.enter", "A.run");
  foo.states.pop();
  foo.check("A.exit", "A.end");
  foo.states.run();
  foo.check("C.enter", "C.exit", "A.start", "A.enter", "A.run");
}

// push state during exit
unittest {
  class C : LoggingState {
    override void exit(Foo foo) { super.exit(foo); foo.states.push(new A); }
  }

  auto foo = new Foo;

  foo.states.push(new C);
  foo.states.run();
  foo.check("C.start", "C.enter", "C.run");
  foo.states.pop();
  foo.states.run();
  foo.check("C.exit", "C.end", "A.start", "A.enter", "A.run");
  foo.states.pop();
}
