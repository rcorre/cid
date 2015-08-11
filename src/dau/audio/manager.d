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

  this() {
    bool ok = al_install_audio();
    assert(ok, "failed to install audio module");

    ok = al_init_acodec_addon();
    assert(ok, "failed to init audio codec addon");

    ok = al_reserve_samples(10);
    assert(ok, "failed to reserve audio samples");
  }

  ~this() {
    unloadSamples();
  }

  void loadSamples(string dir, string glob = "*") {
    bool followSymlink = false;
    foreach(entry ; dir.dirEntries(glob, SpanMode.depth, followSymlink)) {
      auto path = entry.name;
      auto name = path    // the name consists of the path
        .chompPrefix(dir) // minus the directory prefix
        .chompPrefix("/") // minus the leading /
        .stripExtension;  // minus the extension

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
    assert(name in _samples, "no sample named " ~ name);
    return SoundSample(_samples[name]);
  }

  auto playSample(string name) {
    auto sample = getSample(name);
    sample.play();
  }

  static void stopAllSamples() { al_stop_samples(); }
}
