module dau.audio.sound;

import dau.allegro;
import std.typecons : RefCounted, RefCountedAutoInitialize;

alias AudioSample = ALLEGRO_SAMPLE*;
alias SampleInstance = RefCounted!(Payload, RefCountedAutoInitialize.no);

private struct Payload {
  ALLEGRO_SAMPLE_INSTANCE* _instance;
  alias _instance this;

  this(ALLEGRO_SAMPLE *sample) {
    _instance = al_create_sample_instance(sample);
  }

  ~this() { al_destroy_sample_instance(_instance); }

  void play() {
    bool ok = al_play_sample_instance(_instance);
    assert(ok, "Failed to play sample instance");
  }

  void stop() {
    bool ok = al_stop_sample_instance(_instance);
    assert(ok, "Failed to stop sample instance");
  }

  @property {
    bool playing () { return al_get_sample_instance_playing (_instance); }
    auto gain    () { return al_get_sample_instance_gain    (_instance); }
    auto pan     () { return al_get_sample_instance_pan     (_instance); }
    auto speed   () { return al_get_sample_instance_speed   (_instance); }

    void gain  (float val) { al_set_sample_instance_gain  (_instance, val); }
    void pan   (float val) { al_set_sample_instance_pan   (_instance, val); }
    void speed (float val) { al_set_sample_instance_speed (_instance, val); }
  }
}

/++ TODO: pre-create a sample that has 0-length audio?
auto nullAudio() {
  return new BlackHole!AudioSample();
}
++/
