module dau.audio.common;

import dau.allegro;

alias AudioMixer    = ALLEGRO_MIXER*;
alias AudioVoice    = ALLEGRO_VOICE*;
alias AudioSample   = ALLEGRO_SAMPLE*;
alias AudioInstance = ALLEGRO_SAMPLE_INSTANCE*;

enum AudioPlayMode {
  once  = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE,
  loop  = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP,
  bidir = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_BIDIR
}
