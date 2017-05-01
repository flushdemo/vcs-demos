.include "zeropage.inc"
.include "atari2600.inc"
.include "popax.inc"
.include "mBankCall.inc"

.import _bankCall   ; call some code in another bank (jsr _bankCall)
.import _bankReturn ; return to calling code in another bank (jmp _bankReturn)

.import _wait_vblank
.import _wait_overscan
