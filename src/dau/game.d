/**
  * Main entry point for starting a game.
  *
  * Authors: <a href="https://github.com/rcorre">rcorre</a>
	* License: <a href="http://opensource.org/licenses/MIT">MIT</a>
	* Copyright: Copyright © 2015, rcorre
  */
module dau.game;

import std.file   : exists;
import std.path   : buildNormalizedPath, setExtension;
import std.format : format;
import dau.allegro;
import dau.state;
import dau.events;
import dau.util.content;
import dau.graphics;

private enum {
  contentDir = "content",

  bitmapDir = "image",
  fontDir   = "font",

  bitmapExt = ".png",
  fontExt   = ".ttf",
}

/// Main game class.
class Game {
  /// Settings used to configure the game.
  struct Settings {
    int fps;             /// Frames-per-second of update/draw loop
    int numAudioSamples; /// Number of audio samples that can play at once

    Display.Settings display; /// Game window and backbuffer configuration
  }

  @property {
    /// Stack of states that manages game flow.
    auto states() { return _stateStack; }
    /// Access the game window and backbuffer.
    auto display() { return _display; }
    /// Access the event manager.
    auto events() { return _events; }
    /// Render bitmaps to the screen.
    auto renderer() { return _renderer; }
    /// Seconds elapsed between the current frame and the previous frame.
    auto deltaTime() { return _deltaTime; }
    /// Retrieve bitmaps.
    auto bitmaps() { return _bitmaps; }
    /// Retrieve fonts.
    auto fonts() { return _fonts; }
  }

  /**
   * Main entry point for starting a game. Loops until stop() is called on the game instance.
   *
   * Params:
   *  firstState = initial state that the game will begin in
   *  settings = configures the game
   */
  static int run(State!Game firstState, Settings settings) {
    int mainFn() {
      allegroInitAll();
      auto game = new Game(firstState, settings);

      game.run();

      return 0;
    }

    return al_run_allegro(&mainFn);
  }

  /// End the main game loop, causing Game.run to return.
  void stop() {
    _stopped = true;
  }

  private:
  StateStack!Game _stateStack;
  EventManager    _events;
  Renderer        _renderer;
  Display         _display;
  float           _deltaTime;
  bool            _stopped;
  bool            _update;

  // content
  ContentCache!bitmapLoader _bitmaps;
  ContentCache!fontLoader   _fonts;

  this(State!Game firstState, Settings settings) {
    _events   = new EventManager;
    _renderer = new Renderer;
    _display  = Display(settings.display);

    auto queueUpdate(in ALLEGRO_EVENT ev) { _update = true; }

    _events.every(1.0 / settings.fps, &queueUpdate);
    _stateStack.push(firstState);
  }

  void run() {
    while(!_stopped) {
      _events.process();

      if (_update) {
        static float last_update_time = 0;

        float current_time = al_get_time();
        _deltaTime         = current_time - last_update_time;
        last_update_time   = current_time;

        _stateStack.run(this);

        display.clear();
        renderer.render();
        display.flip();

        _update = false;
      }
    }
  }
}

package:
// TODO: private visibility, customizeable path
auto bitmapLoader(string key) {
  auto path = contentDir
    .buildNormalizedPath(bitmapDir, key)
    .setExtension(bitmapExt);

  assert(path.exists, "could not find %s".format(path));
  return Bitmap.load(path);
}

auto fontLoader(string key, int size) {
  auto path = contentDir
    .buildNormalizedPath(fontDir, key)
    .setExtension(fontExt);

  assert(path.exists, "could not find %s".format(path));
  return loadFont(path, size);
}
