module dau.audio.manager;

import std.file   : dirEntries, SpanMode;
import std.path   : stripExtension;
import std.string : toStringz, chompPrefix;
import dau.allegro;
import dau.audio.sound;

class AudioManager {
  private {
    ALLEGRO_SAMPLE*[string] _samples;
  }

  ~this() {
    unloadSamples();
  }

  void loadSamples(string dir, string glob) {
    bool followSymlink = false;
    foreach(entry ; dir.dirEntries(glob, SpanMode.depth, followSymlink)) {
      auto path = entry.name;
      auto name = path.chompPrefix(dir).stripExtension;

      auto sample = al_load_sample(path.toStringz);
      assert(sample, "failed to load " ~ path);

      _samples[name] = sample;
    }
  }

  void unloadSamples() {
    foreach(name, sample ; _samples) al_destroy_sample(sample);
    _samples = null;
  }

  auto getSample(string name) {
    auto sample = name in _samples;
    assert(sample, "no sample named" ~ name);
    return SoundSample(*sample);
  }

  auto playSample(string name) {
    auto sample = getSample(name);
    sample.play();
  }

  static void stopAllSamples() { al_stop_samples(); }
}
