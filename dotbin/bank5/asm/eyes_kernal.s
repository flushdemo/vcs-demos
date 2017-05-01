.include "globals.inc"
.include "banksetup.inc"

.export _eyes_kernal

.import _robot_bg, _eye_data

YPOS1 = tmp1
YEND1 = tmp2
YPOS2 = tmp3
YEND2 = tmp4
EYE1D = ptr1

.segment CODE_SEGMENT
_eyes_kernal:
	popax
	sta YPOS2
	clc
	adc 8
	sta YEND2
	popax
	sta YPOS1
	clc
	adc 8
	sta YEND1
	jsr _wait_vblank
	sta WSYNC

	ldx #0
next_line:
	cpx YPOS1
	bcc no_eye1
	cpx YEND1
	bcs no_eye1
	txa
	sec
	sbc YPOS1
	tay
	lda _eye_data,y
	sta EYE1D
eye2:
	cpx YPOS2
	bcc no_eye2
	cpx YEND2
	bcs no_eye2
	txa
	sec
	sbc YPOS2
	tay
	lda _eye_data,y
continue:
	sta WSYNC
	sta GRP1
	lda EYE1D
	sta GRP0
	lda _robot_bg,x
	sta COLUBK
	inx
	cpx #248
	bne next_line
	jmp end
no_eye1:
	lda #0
	sta EYE1D
	jmp eye2
no_eye2:
	lda #0
	jmp continue
end:
	sta WSYNC
	lda #0
	sta COLUBK
	jmp _bankReturn
