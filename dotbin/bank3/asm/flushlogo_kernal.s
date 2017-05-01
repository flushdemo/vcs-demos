.include "globals.inc"
.include "banksetup.inc"

.export _flushlogo_kernal

.import _flushlogo_bg, _flushlogo_col
.import _flushlogo_pf0, _flushlogo_pf1, _flushlogo_pf2
.import _flushlogo_pf3, _flushlogo_pf4, _flushlogo_pf5

.import _flushlogo_transfo

;;; 104 $00,
;;; 41 - Picture
;;; 103 $00,

HEADER_LEN = 92
PICTURE_LEN = 64

trans_ptr = ptr1
bg_ptr = ptr2

.segment CODE_SEGMENT
_flushlogo_kernal:
	;; Holds background
	popax
	sta bg_ptr
	stx bg_ptr+1
	;; Holds transformation table pointer
	popax
	sta trans_ptr
	stx trans_ptr+1
	;; Set proper background
	ldy #PICTURE_LEN-1
	lda (bg_ptr),y
	sta COLUBK

	jsr _wait_vblank
	sta WSYNC

	ldy #HEADER_LEN
header:
	sta WSYNC
	dey
	bne header

	;; y = 0
next_line:
	lda (trans_ptr),y
	tax
	lda (bg_ptr),y
	sta WSYNC
	sta COLUBK
	lda _flushlogo_col,x
	sta COLUPF
	lda _flushlogo_pf0,x
	sta PF0
	lda _flushlogo_pf1,x
	sta PF1
	lda _flushlogo_pf2,x
	sta PF2
	lda _flushlogo_pf3,x
	sta PF0
	lda _flushlogo_pf4,x
	sta PF1
	lda _flushlogo_pf5,x
	sta PF2
	iny
	cpy #PICTURE_LEN
	bne next_line

	lda #0
	sta WSYNC
	sta PF0
	sta PF1
	sta PF2
	jmp _bankReturn
