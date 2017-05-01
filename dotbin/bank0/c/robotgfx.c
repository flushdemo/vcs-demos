#include "globals.h"
#include "banksetup.h"
#include "song_player.h"

#define DURATION (4*PATTERN_TIME_ZIK2) // 21 secs

void robotgfx_init(void);
void robotgfx_kernal(void);
void robotpf_kernal();
void bg_kernal();
void eyes_fx(void);

struct anim_parms {
  unsigned char aperture;
  unsigned char speed;
  unsigned char pause;
};

static const unsigned char eyescol[] = {
  0x60, 0x62, 0x64, 0x66, 0x68, 0x6a, 0x6c, 0x6e
};

static void kernal_loop(unsigned char count, unsigned char color) {
  unsigned char i;
  for (i=0; i<count; i++) {
    wait_overscan();
    bankCall(color, 0, robotgfx_kernal);
  }
}

static void bg_disp(unsigned char start, unsigned char end) {
  wait_overscan();
  bankCall(start, end, bg_kernal);
}

static void eating_robot(unsigned char gap) {
  TIA.colup0 = eyescol[(tt_cur_vol_c0 & 0x0f)>>1];
  TIA.colup1 = eyescol[(tt_cur_vol_c1 & 0x0f)>>1];
  wait_overscan();
  bankCall(0x00, gap, robotgfx_kernal);
}

static void fixed_bg(void) {
  bankCall(0, 248, bg_kernal);
}

static void fixed_robot(void) {
  bankCall(0x00, 0, robotgfx_kernal);
}

void robotgfx(void) {
  unsigned int i;
  unsigned char aperture = 0;

  // Initialize robot gfx
  wait_overscan();
  bankCall(robotgfx_init);
  wait_vblank();

  // Background intro
  for (i=150; i<248; i+=2) { bg_disp(0, i); }
  // Robot scrolling
  for (i=248; i>0; i-=1) {
    wait_overscan();
    bankCall(i, robotpf_kernal);
  }

  // Fixed eyes for 2 seconds
  TIA.colup0 = TIA.colup1 = 0x66;
  wait_next_pattern(fixed_robot);

  // Eyes blinking in rythm
  for(i=0; i < DURATION-80 ; i++) { // 80 is the blinking time
    // beat_vol value is between 0 and 16
    // beat_vol << 2 is between 0 and 64
    aperture = (beat_vol()<<2) + ((aperture*3)>>2);
    eating_robot((unsigned char) aperture>>3);
  }

  // Blinking before disappearing
  TIA.colup0 = TIA.colup1 = 0x66;
  for (i=0; i<8; i++) {
    kernal_loop(5, 0xfc);
    kernal_loop(5, 0x00);
  }

  cBankCall(eyes_fx);

  // Background outro
  for (i=248; i>150; i-=1) { bg_disp(0, i); }
}
