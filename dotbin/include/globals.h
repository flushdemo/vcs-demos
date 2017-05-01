#include <atari2600.h>

void cdecl bankCall();  // Call functions in another bank
void cdecl cBankCall(); // Call C functions in another bank
void bankReturn(void);  // Return to caller in another bank

extern void wait_overscan(void);
extern void wait_vblank(void);
extern void wait_next_pattern(void (*ckernal)(void));
