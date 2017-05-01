.include "globals.inc"
.include "banksetup.inc"

.export _bg_kernal

.import _robot_bg

BG_START = tmp1
BG_END = tmp2

.segment CODE_SEGMENT
_bg_kernal:
	popax
	sta BG_END
	popax
	sta BG_START
	jsr _wait_vblank
	sta WSYNC

	ldx #0
next_line:
	cpx BG_START
	bcc no_bg
	cpx BG_END
	bcs no_bg
	ldy _robot_bg,x
	jmp display
no_bg:
	ldy #0
display:
	sta WSYNC
	sty COLUBK
	inx
	cpx #248
	bne next_line

	sta WSYNC
	lda #0
	sta COLUBK
	jmp _bankReturn
