module dau.audio.manager;

import std.file   : dirEntries, SpanMode;
import std.path   : stripExtension;
import std.string : toStringz, chompPrefix;
import dau.allegro;
import dau.audio.sound;
import dau.audio.stream;
import dau.audio.common;

class AudioManager {
  private {
    // Mixer Organization:
    // soundMixer  -
    //               \
    //                 -> masterMixer -> voice
    //               /
    // streamMixer -

    AudioSample[string] _samples;
    AudioVoice          _voice;       // the audio output device
    AudioMixer          _masterMixer; // mixer connected directly to voice
    AudioMixer          _streamMixer; // mixer for music
    AudioMixer          _soundMixer;  // mixer for sound effects
  }

  this() {
    bool ok = al_install_audio();
    assert(ok, "failed to install audio module");

    ok = al_init_acodec_addon();
    assert(ok, "failed to init audio codec addon");

    // TODO: use game settings to configure these options
    _voice = al_create_voice(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_INT16,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    _masterMixer = al_create_mixer(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_FLOAT32,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    _streamMixer = al_create_mixer(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_FLOAT32,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    _soundMixer = al_create_mixer(44100,
        ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_FLOAT32,
        ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);

    assert(_voice,       "failed to create audio voice");
    assert(_streamMixer, "failed to create audio stream mixer");
    assert(_soundMixer,  "failed to create sound effect mixer");
    assert(_masterMixer, "failed to create master audio mixer");

    ok = al_attach_mixer_to_mixer(_soundMixer, _masterMixer);
    assert(ok, "failed to attach sound mixer to voice");

    ok = al_attach_mixer_to_mixer(_streamMixer, _masterMixer);
    assert(ok, "failed to attach sound mixer to voice");

    ok = al_attach_mixer_to_voice(_masterMixer, _voice);
    assert(ok, "failed to attach master audio mixer to voice");
  }

  ~this() {
    al_destroy_mixer(_soundMixer);
    al_destroy_mixer(_streamMixer);
    al_destroy_mixer(_masterMixer);
    al_destroy_voice(_voice);
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

  auto getSound(string name) {
    assert(name in _samples, "no sample named " ~ name);
    auto sound = SoundEffect(_samples[name]);
    al_attach_sample_instance_to_mixer(sound, _soundMixer);
    return sound;
  }

  auto playSound(string name) {
    auto sample = getSound(name);
    sample.play();
  }

  static void stopAllSamples() { al_stop_samples(); }

  auto loadStream(string path, size_t bufferCount = 4, uint samples = 1024) {
    import std.string : toStringz;
    auto stream = al_load_audio_stream(path.toStringz, 4, 1024);
    al_attach_audio_stream_to_mixer(stream, _streamMixer);
    return AudioStream(stream);
  }
}
