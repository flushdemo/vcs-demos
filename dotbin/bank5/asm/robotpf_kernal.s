.include "globals.inc"
.include "banksetup.inc"

.export _robotpf_kernal

.import _robot_bg, _robot_col
.import _robot_pf0, _robot_pf1, _robot_pf2
.import _robot_pf3, _robot_pf4, _robot_pf5

PF_SKIP = tmp1

.segment CODE_SEGMENT
_robotpf_kernal:
	popax
	sta PF_SKIP
	jsr _wait_vblank
	sta WSYNC

	ldx #0
	ldy #0
next_line:
	cpx PF_SKIP
	bcc no_pf
	lda _robot_bg,x
	sta WSYNC
	sta COLUBK
	lda _robot_col,y
	sta COLUPF
	lda _robot_pf0,y
	sta PF0
	lda _robot_pf1,y
	sta PF1
	lda _robot_pf2,y
	sta PF2
	lda _robot_pf3,y
	sta PF0
	lda _robot_pf4,y
	sta PF1
	lda _robot_pf5,y
	sta PF2
	iny
	jmp continue
no_pf:
	lda _robot_bg,x
	sta WSYNC
	sta COLUBK
continue:
	inx
	cpx #248
	bne next_line

	lda #0
	sta WSYNC
	sta COLUBK
	sta COLUPF
	sta PF0
	sta PF1
	sta PF2
	jmp _bankReturn
