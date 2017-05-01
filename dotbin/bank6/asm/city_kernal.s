.include "globals.inc"
.include "banksetup.inc"

.export _city_kernal

.import _city_bg
.import _city_pf0, _city_pf1, _city_pf2
.import _city_pf3, _city_pf4, _city_pf5
.import _city_sprite1, _city_sprite2

sprite_off = tmp1
lines_cnt = tmp2
lines_off = tmp3
bg_col = tmp4
bg_ptr = ptr1

BG_OFFSET = 107

.segment CODE_SEGMENT
_city_kernal:
	;; 54 lines sprites zone
	;; Though skipping the 10 first lines
	popax
	sta sprite_off
	popax
	sta lines_off
	popax
	sta bg_ptr
	stx bg_ptr+1
	ldy #0
	sty lines_cnt
	sty COLUBK
	lda (bg_ptr),y
	sta bg_col
	jsr _wait_vblank

	ldx #10
blank_zone:
	sta WSYNC
	lda lines_cnt
	cmp lines_off
	;; Don't draw if lines_cnt < lines_off
	;; sub is <0 -> carry is cleared
	bcc blank_cont

	lda bg_col
	sta COLUBK
blank_cont:
	inc lines_cnt
	dex
	bne blank_zone

	ldx #0
	ldy sprite_off
sprite_zone:
	lda lines_cnt
	cmp lines_off
	bcs sprite_draw
	sta WSYNC
	jmp sprite_cont
sprite_draw:
	lda bg_col
	sta WSYNC
	sta COLUBK
	lda _city_sprite1,x
	sta GRP0
	lda _city_sprite2,y
	sta GRP1
sprite_cont:
	inx
	iny
	inc lines_cnt
	cpx #44			; 44 sprites lines
				; Sprite 1 doesn't move
	bne sprite_zone

	ldy #0
	sty GRP0
	sty GRP1
	ldx lines_cnt		; Using x reg for speed
citynb_zone:
	cpx lines_off
	bcs citynb_draw
	sta WSYNC
	jmp citynb_cont
citynb_draw:
	sta WSYNC
	lda bg_col
	sta COLUBK
	lda _city_pf0,y
	sta PF0
	lda _city_pf1,y
	sta PF1
	lda _city_pf2,y
	sta PF2
	lda _city_pf3,y
	sta PF0
	lda _city_pf4,y
	sta PF1
	lda _city_pf5,y
	sta PF2
citynb_cont:
	inx
	iny
	cpy #BG_OFFSET		; BG_OFFSET lines withouh BG
	bne citynb_zone

	ldy #0
citybg_zone:
	cpx lines_off
	bcs citybg_draw
	sta WSYNC
	jmp citybg_cont
citybg_draw:
	sta WSYNC
	lda (bg_ptr),y
	sta COLUBK
	lda _city_pf0+BG_OFFSET,y
	sta PF0
	lda _city_pf1+BG_OFFSET,y
	sta PF1
	lda _city_pf2+BG_OFFSET,y
	sta PF2
	lda _city_pf3+BG_OFFSET,y
	sta PF0
	lda _city_pf4+BG_OFFSET,y
	sta PF1
	lda _city_pf5+BG_OFFSET,y
	sta PF2
citybg_cont:
	inx
	iny
	cpy #(248 - 54 - BG_OFFSET)
	bne citybg_zone

	lda #0
	sta WSYNC
	sta COLUBK
	sta COLUPF
	sta PF0
	sta PF1
	sta PF2
	jmp _bankReturn
