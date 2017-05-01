#include "globals.h"
#include "banksetup.h"
#include "song_player.h"

#define FX_DURATION (PATTERN_TIME_ZIK1 * 12)

void fx_pf_setup(void);
void fx_pf_kernel(void);

void fx_pf(void) {
  unsigned int i;
  wait_overscan();
  cBankCall(fx_pf_setup);
  wait_vblank();
  for(i=0; i<FX_DURATION; i++) {
    wait_overscan();
    cBankCall(bgcolor_beat);
    cBankCall(fx_pf_kernel);
  }
}
