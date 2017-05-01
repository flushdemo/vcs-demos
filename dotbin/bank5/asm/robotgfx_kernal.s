.include "globals.inc"
.include "banksetup.inc"

.export _robotgfx_init, _robotgfx_kernal

.import _robot_bg, _robot_col, _robot_eye
.import _robot_pf0, _robot_pf1, _robot_pf2, _robot_pf3, _robot_pf4, _robot_pf5

ROBOT_COL = tmp1
ROBOT_SHIFT = tmp2
LOPF_START = tmp3

SPLIT = 144			; Separation between high and low head part

.segment CODE_SEGMENT
_robotgfx_init:
	lda #68
	sta COLUP0
	sta COLUP1
	lda #0
	sta NUSIZ0
	sta NUSIZ1

	;; Positionning eyes
	sta WSYNC
	.repeat 18
	nop
	.endrepeat
	sta RESP0
	.repeat 5
	nop
	.endrepeat
	sta RESP1
	lda #$e0
	sta HMP0
	lda #$d0
	sta HMP1
	sta WSYNC
	sta HMOVE
	jmp _bankReturn


.mac update_pf0_sprites_bg XY
	lda _robot_pf0,XY
	sta PF0
	lda _robot_eye,XY
	sta GRP0
	sta GRP1
	sta WSYNC
	lda _robot_bg,x
	sta COLUBK
.endmac

.mac update_pf0_bg XY
	lda _robot_pf0,XY
	sta PF0
	sta WSYNC
	lda _robot_bg,x
	sta COLUBK
.endmac

.mac update_other_pf XY
	lda _robot_pf1,XY
	sta PF1
	lda _robot_pf2,XY
	sta PF2
	lda _robot_pf3,XY
	sta PF0
	lda _robot_pf4,XY
	sta PF1
	lda _robot_pf5,XY
	sta PF2
.endmac

.mac clear_gfx_regs
	lda #0
	sta WSYNC
	sta COLUBK
	sta COLUPF
	sta PF0
	sta PF1
	sta PF2
.endmac


.segment CODE_SEGMENT
.align 256
_robotgfx_kernal:
	popax
	sta ROBOT_SHIFT
	lda #SPLIT
	clc
	adc ROBOT_SHIFT
	sta LOPF_START
	popax
	sta ROBOT_COL
	cmp #0
	bne mono_gfx
	jmp colo_gfx

mono_gfx:
.scope
	jsr _wait_vblank
	sta WSYNC
	ldx ROBOT_SHIFT
next_line:
	update_pf0_sprites_bg x
	lda ROBOT_COL
	sta COLUPF
	update_other_pf x
	inx
	cpx #248
	bne next_line

	clear_gfx_regs
	jmp _bankReturn
.endscope


colo_gfx:
.scope
	jsr _wait_vblank
	sta WSYNC
	ldx ROBOT_SHIFT
next_hi_line:
	update_pf0_sprites_bg x
	lda _robot_col,x
	sta COLUPF
	update_other_pf x
	inx
	cpx #SPLIT-1		; Stopping hi part 1 line before
	bne next_hi_line

;;; Skip ROBOT_SHIFT lines
	ldx ROBOT_SHIFT
	beq lo_line
skip:
	sta WSYNC
	dex
	bne skip
	jmp lo_line

.segment CODE_SEGMENT
.align 256
lo_line:
	;; Blank line at junction to sync
	lda #0
	sta WSYNC
	sta COLUPF
	sta COLUBK
	ldx #SPLIT
	ldy #SPLIT
next_lo_line:
	cpx LOPF_START
	bcc no_pf
	update_pf0_bg y
	lda _robot_col,y
	sta COLUPF
	update_other_pf y
	iny
	jmp continue
no_pf:
	lda _robot_bg,x
	sta WSYNC
	sta COLUBK
continue:
	inx
	cpx #248
	bne next_lo_line

	clear_gfx_regs
	jmp _bankReturn
.endscope
