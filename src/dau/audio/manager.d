module dau.audio.manager;

import std.file   : dirEntries, SpanMode;
import std.path   : stripExtension;
import std.string : toStringz, chompPrefix;
import dau.allegro;
import dau.audio.sound;

alias AudioStream = ALLEGRO_AUDIO_STREAM*;
alias AudioMixer = ALLEGRO_MIXER*;
alias AudioVoice = ALLEGRO_VOICE*;

class AudioManager {
  private {
    ALLEGRO_SAMPLE*[string] _samples;
    AudioVoice              _voice;
    AudioMixer              _streamMixer;
  }

  this() {
    bool ok = al_install_audio();
    assert(ok, "failed to install audio module");

    ok = al_init_acodec_addon();
    assert(ok, "failed to init audio codec addon");

    ok = al_reserve_samples(10);
    assert(ok, "failed to reserve audio samples");

    // TODO: use game settings to configure these options
    _voice = al_create_voice(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_INT16,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    _streamMixer = al_create_mixer(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_FLOAT32,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    assert(_voice, "failed to create audio voice");
    assert(_streamMixer, "failed to create audio stream mixer");

    ok = al_attach_mixer_to_voice(_streamMixer, _voice);
    assert(ok, "failed to attach mixer to voice");
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

  auto loadStream(string path, size_t bufferCount = 4, uint samples = 1024) {
    import std.string : toStringz;
    auto stream = al_load_audio_stream(path.toStringz, 4, 1024);
    al_attach_audio_stream_to_mixer(stream, _streamMixer);
    return stream;
  }
}

auto gain(AudioStream stream) {
  return al_get_audio_stream_gain(stream);
}

void gain(AudioStream stream, float val) {
  bool ok = al_set_audio_stream_gain(stream, val);
  assert(ok, "failed to set audio stream gain");
}

auto playMode(AudioStream stream) {
  return al_get_audio_stream_playmode(stream);
}

void playMode(AudioStream stream, AudioPlayMode mode) {
  bool ok = al_set_audio_stream_playmode(stream, mode);
  assert(ok, "failed to set audio stream playmode");
}

void unload(AudioStream stream) {
  al_destroy_audio_stream(stream);
}
