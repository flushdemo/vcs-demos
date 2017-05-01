.include "globals.inc"
.include "banksetup.inc"

.export _logostretch_kernal

.import _flushlogo_bg, _flushlogo_col
.import _stretch_pf0, _stretch_pf1, _stretch_pf2
.import _stretch_pf3, _stretch_pf4, _stretch_pf5

;;; 104 $00,
;;; 41 - Picture
;;; 103 $00,

HEADER_LEN = 104
PICTURE_LEN = 5

logo_bg = _flushlogo_bg + 11 	; displaying 35 center lines
logo_col = _flushlogo_col + 2

offset = tmp1
top = tmp2

.segment CODE_SEGMENT
_logostretch_kernal:
	;; Holds transformation table pointer
	popax
	sta offset
	clc
	adc #5
	sta top
	;; Set proper background
	ldy #PICTURE_LEN-1
	lda logo_bg,y
	sta COLUBK

	jsr _wait_vblank
	sta WSYNC

	ldy #HEADER_LEN
header:
	sta WSYNC
	dey
	bne header

	ldx #0
	ldy offset
next_line:
.repeat 8
	lda logo_bg,x
	sta WSYNC
	sta COLUBK
	lda logo_col,x
	sta COLUPF
	lda _stretch_pf0,y
	sta PF0
	lda _stretch_pf1,y
	sta PF1
	lda _stretch_pf2,y
	sta PF2
	lda _stretch_pf3,y
	sta PF0
	lda _stretch_pf4,y
	sta PF1
	lda _stretch_pf5,y
	sta PF2
	inx
.endrepeat
	iny
	cpy top
	beq end
	jmp next_line

end:
	lda #0
	sta WSYNC
	sta PF0
	sta PF1
	sta PF2
	jmp _bankReturn
