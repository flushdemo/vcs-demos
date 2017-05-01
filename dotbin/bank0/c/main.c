#include "globals.h"
#include "banksetup.h"
#include "song_player.h"
#include "vc_texts.h"

/*******/
/* FXs */
/*******/

// External functions
void citygfx(void);
void flushlogo(void);
void fixed_flushlogo(void);
void fx_vrgirl(void);
void fx_pf(void);
void palette_kernal(void);
void robotgfx(void);

void init_vcs_print_kernal(void);
void vcs_print(const unsigned char offset,
	       const unsigned char count,
	       const unsigned char data[]);

static void wait_and_call(void (*fn)(void)) {
  wait_overscan();
  wait_vblank();
  bankCall(fn);
}

void wait_next_pattern(void (*ckernal)(void)) {
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

static void blank_screen(unsigned int count, unsigned char color) {
  unsigned int i;
  for(i=0; i<count; i++) {
    wait_overscan();
    TIA.colubk = color;
    wait_vblank();
  }
}

static void wait_frames(unsigned int count, void (*ckernal)(void)) {
  unsigned int i;
  for(i=0; i<count; i++) {
    wait_overscan();
    if (ckernal == 0) {
      TIA.colubk = 0; // Turning screen black
      wait_vblank();
    } else {
      cBankCall(ckernal);
    }
  }
}

void main(void) {
  unsigned char col;
  //fx_vrgirl();
  /* Main Loop (i.e: Demo Timeline) */
  // 28 patterns for 'forward' song
  // We want to change at the end of 2nd pattern
  // So 30 patterns to play
  wait_and_call(forward_tt_init);
  wait_frames(10, palette_kernal); // Arbitrary number > 2
  wait_next_pattern(palette_kernal);

  wait_and_call(init_vcs_print_kernal);
  vcs_print(140, FLUSH_PRESENTS_LEN, flush_presents);
//  vcs_print(100, DOT_BIN_LEN, dot_bin);
  vcs_print(50, ATARI_DEMO_LEN, atari_demo);
  // 5 patterns elapsed

  fx_vrgirl();
  fx_pf();

  wait_and_call(salami_tt_init);
  wait_frames(10, 0); // Arbitrary number > 2
  wait_next_pattern(0);
  citygfx();
  wait_and_call(init_vcs_print_kernal);
  vcs_print(60, ENJOY_GRAPHICS_LEN, enjoy_graphics);
  robotgfx();

  wait_and_call(init_vcs_print_kernal);
  vcs_print(120, RELEASED_AT_LEN, released_at);
  vcs_print(50, REVISION2017_LEN, revision2017);
  wait_next_pattern(0);

  cBankCall(flushlogo);
  wait_next_pattern(fixed_flushlogo);

  wait_and_call(koniec_tt_init);
  wait_and_call(init_vcs_print_kernal);

  for (col = 0x0e; col > 0; col--) {
    blank_screen(10, col);
  }
  blank_screen(10, 0);

  vcs_print(20, GRAPHICS_MUSICS_LEN, graphics_musics);
  vcs_print(40, CODE_LEN, code);
  vcs_print(110, MUSIC_POWERED_LEN, music_powered);
  vcs_print(20, CODE_POWERED_LEN, code_powered);
  vcs_print(20, GREETS_1_LEN, greets_1);
  vcs_print(40, GREETS_2_LEN, greets_2);
  vcs_print(18, ASCIIART_1_LEN, asciiart_1);
  vcs_print(18, ASCIIART_2_LEN, asciiart_2);
  vcs_print(18, ASCIIART_3_LEN, asciiart_3);
  vcs_print(60, ASCIIART_4_LEN, asciiart_4);
  vcs_print(120, REBOOT_LEN, reboot);
  wait_next_pattern(0);

  asm("jmp ($1FFC)"); // reset
}
