#include "globals.h"
#include "banksetup.h"
#include "song_player.h"

unsigned char beat_vol(void) {
  unsigned char pvol = 0;
  // instruments < 0x20 are percussions
  if (tt_cur_ins_c0 < 0x20) { pvol = tt_cur_vol_c0&0xf; }
  if (tt_cur_ins_c1 < 0x20) {
    pvol = tt_cur_vol_c1&0xf > pvol ? tt_cur_vol_c1&0xf : pvol;
  }
  return pvol;
}

void bgcolor_beat(void) {
  TIA.colubk = 0xf0 | beat_vol();
}
