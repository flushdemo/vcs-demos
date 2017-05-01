#include "globals.h"
#include "banksetup.h"
#include "song_player.h"

#define FX_DURATION (4*PATTERN_TIME_ZIK2 + 248/2) // 19 secs

void city_kernal(void);

extern unsigned char city_bg[];
extern unsigned char city_flash[];

void citygfx(void) {
  unsigned int i, j;
  unsigned int imod;
  unsigned char sprite_off = 0;
  unsigned char* bg_table;

  // Initialize city gfx
  TIA.nusiz0 = 0;
  TIA.nusiz1 = 5;
  TIA.refp0 = 0;
  TIA.refp1 = 8;
  TIA.hmp0 = 0xff<<4;
  TIA.hmp1 = 2<<4;
  TIA.colup0 = 0;
  TIA.colup1 = 0;
  TIA.colupf = 0;
  wait_overscan();
  wait_vblank();

  for(i=0; i<FX_DURATION; i++) {
    imod = i & 0x01ff; // mod 512 but faster
    if (imod >= 108) {
      if (imod < 128) {
	sprite_off++;
      }
      else {
	if (imod >= 236) {
	  if (imod < 256) {
	    sprite_off--;
	  }
	  else {
	    if (imod >= 354) {
	      if (imod < 384) {
		sprite_off++;
	      }
	      else {
		if (imod >= 482) {
		  sprite_off--;
		}
	      }
	    }
	  }
	}
      }
    }

    j = 0; // Draw the whole picture by default
    if (i < 248) {
      j = 248-i;
    }
    else if (i > FX_DURATION-248/2) {
      j = (i + 248/2 - FX_DURATION)<<1;
    }
    // j 0 -> 248
    // i FX_DURATION-248/2 -> FX_DURATION
    // j = (i - (FX_DURATION-248/2))*2

    // Choose background table according to beat
    if (beat_vol() > 0x08) {
      bg_table = city_flash;
    } else {
      bg_table = city_bg;
    }

    // Move sprites
    TIA.wsync = 0;
    TIA.hmove = 0;
    wait_overscan();
    bankCall(bg_table, j, sprite_off, city_kernal);
  }
}
