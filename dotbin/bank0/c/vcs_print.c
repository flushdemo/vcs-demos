#include "globals.h"
#include "banksetup.h"
#include "song_player.h"

#define CHARS_PER_LINE 12

#define TEXT_SPEED 2
#define CURSOR_SPEED 25
#define DISP_DURATION 3

/*
 * offset the number of lines to skip
 * lines is the number of lines to display
 * cursor is the index in the fonts table of the character to display as the cursor
 * count is the total number of characters to display
 * data is a pointer to the text to display
 */
extern void vcs_print_kernal();

void display_screen(const unsigned char offset,
		    const unsigned char lines,
		    const unsigned char cursor,
		    const unsigned char count,
		    const unsigned char* data) {
  wait_overscan();
  cBankCall(bgcolor_beat);
  bankCall(offset, lines, cursor, count, data, vcs_print_kernal);
}

/*
 * count is the total number of characters to display
 * data is a pointer to the text to display
 */
void vcs_print(unsigned char offset,
	       unsigned char count,
	       unsigned char* data) {
  unsigned char i;
  unsigned char j;
  const unsigned char lines = (count/CHARS_PER_LINE) + 1;

  /* Some initialization */
  TIA.nusiz0 = 0x06;
  TIA.nusiz1 = 0x06;
  TIA.colup0 = 0x6a;
  TIA.colup1 = 0x7a;
  TIA.refp0 = 0;
  TIA.refp1 = 0;

  for(i=0; i<count; i++) {
    for(j=0; j<TEXT_SPEED; j++)
      display_screen(offset, lines, 0xf8, i, data);
  }
  for(i=0; i<DISP_DURATION; i++) {
    for(j=0; j<CURSOR_SPEED; j++)
      display_screen(offset, lines, 0xf8, count, data);
    for(j=0; j<CURSOR_SPEED; j++)
      display_screen(offset, lines, 0x00, count, data);
  }
  for(i=128; i<128+count; i++) {
    for(j=0; j<TEXT_SPEED; j++)
      display_screen(offset, lines, 0xf8, i, data);
  }
}
