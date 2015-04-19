module dau.system;

import dau.input;
import dau.game;

/// Represents a process that manipulates the `Game` once each frame while it is active.
abstract class System {
  this(Game game) {
    _game = game;
  }

  @property {
    /// A `System`'s update function is only called when it is `active`.
    /// Toggling `active` will call the system's `start` or `stop` method as needed.
    bool active() { return _active; }

    /// ditto
    void active(bool val) { 
      if (!active && val) {
        start();
      }
      else if (active && !val) {
        stop();
      }
      _active = val;
    }

    auto game() { return _game; }
  }

  /// Called each frame while this system is `active`.
  void update(float time, InputManager input);

  /// Called when `active` is set to `true`.
  void start();

  /// Called when `active` is set to `false`.
  void stop();

  private bool _active;
  private Game _game;
}
