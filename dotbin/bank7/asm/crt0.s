; Flush, 2017
	.include "globals.inc"

        .export         _start, _exit
        .export         __STARTUP__ : absolute = 1

        .import         __RAM_START__, __RAM_SIZE__
        .import         _main


.segment "STARTUP"

_start:
; Clear decimal mode
        cld

; Initialization Loop:
; * Clears Atari 2600 whole memory (128 bytes) including BSS segment
; * Clears TIA registers
; * Sets system stack pointer to $ff (i.e top of zero-page)
        ldx     #0
        txa
clearLoop:
        dex
        txs
        pha
        bne     clearLoop

; Initialize C stack pointer
        lda     #<(__RAM_START__ + __RAM_SIZE__)
        ldx     #>(__RAM_START__ + __RAM_SIZE__)
        sta     sp
        stx     sp+1

; Call main
        mBankJump	_main
_exit:  jmp     _exit
