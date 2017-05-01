.include "globals.inc"
.include "banksetup.inc"

.export _palette_kernal

.segment CODE_SEGMENT

_palette_kernal:
	jsr _wait_vblank

	;; Skip first 6 lines
	ldx #6
skip_header:
	sta WSYNC
	dex
	bne skip_header

	clc
	ldx #0
next_line:
	.repeat 14
	sta WSYNC
	txa
	sta COLUBK
	.repeat 9
	nop
	.endrepeat
	.repeat 7
	adc #$02
	sta COLUBK
	nop
	.endrepeat
	.endrepeat

	sta WSYNC
	lda #$0
	sta COLUBK
	txa
	adc #$10
	tax
	bcs end
	jmp next_line
end:
	;; jmp _bankReturn
	;; This kernal must now be called with cBankCall
	rts
