module dau.setup;

import dau.graphics.color;

alias InitFunction = void function();
alias ShutdownFunction = void function();

/// Settings used to configure the game.
struct GameSettings {
  int fps;             /// Frames-per-second of update/draw loop
  int screenWidth;     /// Horizontal window size in pixels
  int screenHeight;    /// Vertical window size in pixels
  int numAudioSamples; /// Number of audio samples that can play at once
  string iconPath;     /// Path to icon to use for app
  Color bgColor;       /// Color used to clear screen before drawing.
}

//TODO: this has to be replaced by something configurable.
/// paths to configuration files and content
enum Paths : string {
  bitmapDir     = "content/image",
  fontDir       = "content/font",
  soundDir      = "content/sound",
  musicDir      = "content/music",
  musicData     = "content/music.cfg",
  mapDir        = "content/maps",
  textureData   = "data/textures.json",
  guiData       = "data/gui.json",
  unitData      = "data/units.json",
  factionData   = "data/factions.json",
  aiData        = "data/ai.json",
  preferences   = "save/preferences.json",
}

void onInit(InitFunction fn) {
  _initializers ~= fn;
}

void onShutdown(ShutdownFunction fn) {
  _deInitializers ~= fn;
}

package:
void runSetupFunctions() {
  assert(!_setup, "tried to run setup functions twice");
  foreach(fn ; _initializers) {
    fn();
  }
  _setup = true;
}

void runShutdownFunctions() {
  assert(!_shutdown, "tried to run shutdown functions twice");
  foreach(fn ; _deInitializers) {
    fn();
  }
  _shutdown = true;
}

private:
bool _setup, _shutdown;
InitFunction[] _initializers;
ShutdownFunction[] _deInitializers;
