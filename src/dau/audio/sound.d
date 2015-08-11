module dau.audio.sound;

import dau.allegro;

enum SoundPlayMode {
  once  = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE,
  loop  = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP,
  bidir = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_BIDIR
}

struct SoundSample {
  float         gain  = 1;
  float         pan   = 0;
  float         speed = 1;
  SoundPlayMode mode  = SoundPlayMode.once;

  this(ALLEGRO_SAMPLE* sample) {
    _sample = sample;
  }

  void play() {
    bool ok = al_play_sample(_sample, gain, pan, speed, mode, &_id);
    assert(ok, "a sound sample failed to play");
  }

  void stop() {
    al_stop_sample(&_id);
  }

  private:
  ALLEGRO_SAMPLE*   _sample;
  ALLEGRO_SAMPLE_ID _id;
}

/++ TODO: pre-create a sample that has 0-length audio?
auto nullAudio() {
  return new BlackHole!AudioSample();
}
++/
