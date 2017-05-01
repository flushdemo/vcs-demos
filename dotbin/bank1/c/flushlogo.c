#include "globals.h"
#include "banksetup.h"
#include "song_player.h"

#define FX_1STPART 320 // Approx 7 secs
#define FX_2NDPART (3*PATTERN_TIME_ZIK2) // 10 secs

void flushlogo_kernal();
void logostretch_kernal();

extern unsigned char flushlogo_bg[];
extern unsigned char flushlogo_bg_light[];
extern unsigned char flushlogo_transfo[];

// TODO - Factorize this with main's method
static void wait_next_pattern_logo(void (*ckernal)(void)) {
  while (tt_cur_note_index_c0 != 1) {
    wait_overscan();
    if (ckernal == 0) {
      TIA.colubk = 0; // Turning screen black
      wait_vblank();
    } else {
      cBankCall(ckernal);
    }
  }
}

const signed char rotation[] = {
16, 16, 17, 18, 19, 19, 20, 21, 22, 22, 23, 24, 24, 25, 26, 26, 27, 27, 28, 28, 29, 29, 30, 30, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 30, 30, 30, 29, 29, 28, 28, 27, 27, 26, 26, 25, 24, 24, 23, 22, 22, 21, 20, 19, 19, 18, 17, 16, 16, 15, 14, 13, 12, 12, 11, 10, 9, 9, 8, 7, 7, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 7, 8, 9, 9, 10, 11, 12, 12, 13, 14, 15
};

const signed char bg_shift[] = {
6, 6, 6, 5, 5, 4, 4, 3, 3, 3, 2, 2, 1, 1, 0, 0, -1, -1, -2, -2, -3, -3, -4, -4, -4, -5, -5, -6, -6, -7, -7, -7
};

const signed char logorot[] = {
0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
};

void fixed_flushlogo(void) {
  bankCall(flushlogo_transfo + (int)((int)rotation[0]<<6),
	   flushlogo_bg + bg_shift[rotation[0]],
	   flushlogo_kernal);
}

void callFlushlogoKernal(int tr_offset, signed char bg_offset) {
  wait_overscan();
  bankCall(flushlogo_transfo + tr_offset,
	   flushlogo_bg + bg_offset,
	   flushlogo_kernal);
}
void callFlushlogoKernalLight(int tr_offset, signed char bg_offset) {
  wait_overscan();
  bankCall(flushlogo_transfo + tr_offset,
	   flushlogo_bg_light + bg_offset,
	   flushlogo_kernal);
}

void flushlogo(void) {
  unsigned int j;
  unsigned char rotidx;
  unsigned char pvol;

  for (j=0; j<17; j++) {
    wait_overscan();
    bankCall(j*5, logostretch_kernal);
  }

  wait_next_pattern_logo(fixed_flushlogo);

  for (j=0; j<FX_1STPART; j++) {
    callFlushlogoKernal((int)rotation[j&0x7f]<<6, bg_shift[rotation[j&0x7f]]);
  }

  wait_next_pattern_logo(fixed_flushlogo);

  rotidx = 20;
  for (j=0; j<FX_2NDPART; j++) {
    pvol = 0;
    if (tt_cur_ins_c0 <= 0x20) { pvol = tt_cur_vol_c0&0xf; }
    if (tt_cur_ins_c1 <= 0x20) {
      pvol = tt_cur_vol_c1&0xf > pvol ? tt_cur_vol_c1&0xf : pvol;
    }
    rotidx = (rotidx+(pvol>>2)) % sizeof(logorot);

    if (pvol>>3) {
      callFlushlogoKernalLight((int)logorot[rotidx]<<6, bg_shift[logorot[rotidx]]);
    } else {
      callFlushlogoKernal((int)logorot[rotidx]<<6, bg_shift[logorot[rotidx]]);
    }
  }
}
