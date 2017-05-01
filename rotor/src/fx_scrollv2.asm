TEXT_WIDTH = 4

fx_scrollv2_setup SUBROUTINE
	;; Standard initialization there
	lda #$00
	sta ENABL       ; Turn off ball, missiles and players
	sta ENAM0
	sta ENAM1
	sta GRP0
	sta GRP1
	sta COLUBK      ; Background color (black)
	sta PF0         ; Initializing PFx to 0
	sta PF1
	sta PF2
	lda #$FF        ; Playfield collor (yellow-ish)
	sta COLUPF
	lda #$00        ; Ensure we will duplicate (and not reflect) PF
	sta CTRLPF

	lda #0
	sta frame_cnt
	sta col_start
	lda #4
	sta line_cnt

	lda #<alphabet
	sta scr_line_pt
	lda #>alphabet
	sta scr_line_pt+1

	lda #<scroll_text
	sta scr_text_pt
	lda #>scroll_text
	sta scr_text_pt+1

	lda #0
	sta bg_sta_lo
	sta bg_sta_hi
	sta bg_vec_lo
	lda #1
	sta bg_vec_hi

	;; Clean frame buffer
	lda #0
LINE_NUM SET 7
	REPEAT 8
	sta fb0 + LINE_NUM
	sta fb1 + LINE_NUM
	sta fb2 + LINE_NUM
	sta fb3 + LINE_NUM
	sta fb4 + LINE_NUM
	sta fb5 + LINE_NUM
LINE_NUM SET LINE_NUM - 1
	REPEND
	rts

fx_scrollv2_overscan SUBROUTINE
	inc frame_cnt
	rts

;compute_frame SUBROUTINE
fx_scrollv2_vblank SUBROUTINE
	;; Initializing frame stuff
	lda bg_sta_hi
	sta bg_idx_hi
	lda bg_sta_lo
	sta bg_idx_lo

	;; translate background
	lda frame_cnt
	and #$3f
	tax
	lda scroll_bg_trans,X
	sta bg_sta_hi

	;; scale background
	lda frame_cnt
	;and #$7f
	tax
	lda scroll_bg_scale,X
	sta bg_vec_lo

	lda frame_cnt
	and #$01		; Odd or even ?
	beq .process_line
	rts

.process_line
	ldy #0
	lda (scr_line_pt),Y
	sta cur_line

	ldx #7			; Processing 8 lines
.scroll_line
	;; Getting each bit in the carriage flag
	lsr cur_line
	;; P0: 4 highest bits reverse order
	;; P1: 8 bits normal order
	;; P2: 8 bits reverse order
	ror fb5,X
	rol fb4,X
	ror fb3,X
	;; Skipping 4 least significant bits
	lda fb3,X
	lsr
	lsr
	lsr
	lsr
	ror fb2,X
	rol fb1,X
	ror fb0,X
	dex
	bpl .scroll_line

	;; Preparing next line to display
	lda line_cnt
	bpl .next_line
.next_char
	lda #1
	clc
	adc scr_text_pt
	sta scr_text_pt
	lda #0
	adc scr_text_pt+1
	sta scr_text_pt+1

	ldy #0
	lda (scr_text_pt),Y
	cmp #$7E
	bne .character_graphic
	lda #<scroll_text
	sta scr_text_pt
	lda #>scroll_text
	sta scr_text_pt+1
	lda #$20

.character_graphic
	and #$3F		; Using 6 low bits as index on chars
	asl			; And multiply by 6 (6 lines per char)
	sta tmp_var
	asl
	clc			; 16 bits addition to alphabet @
	adc #<alphabet
	sta scr_line_pt
	lda #0
	adc #>alphabet
	sta scr_line_pt+1
	lda tmp_var
	clc
	adc scr_line_pt
	sta scr_line_pt
	lda #0
	adc scr_line_pt+1
	sta scr_line_pt+1

	lda #4
	sta line_cnt
	rts
.next_line
	lda 1
	clc
	adc scr_line_pt
	sta scr_line_pt
	lda #0
	adc scr_line_pt+1
	sta scr_line_pt+1

	dec line_cnt
	rts

;;; Next background color
	;; Splitting background computation, to be able to do it in several steps
	mac NEXT_BG_LOW
	clc			; 2
	lda bg_idx_lo		; 3
	adc bg_vec_lo		; 3
	sta bg_idx_lo		; 3
	endm
	mac NEXT_BG_HIGH
	lda bg_idx_hi		; 3
	adc bg_vec_hi		; 3
	sta bg_idx_hi		; 3
	tay			; 3
	lda scroll_background,Y	; 4
	endm
	mac NEXT_BG_COLOR
	;; Compute next background color
	;; 16 bits addition
	;; cost 27
	NEXT_BG_LOW
	NEXT_BG_HIGH
	endm

;;; Display one line
	mac DRAW_ONE_LINE
	sta WSYNC		; 3
	;; HBLANK is 68 clocks count i.e 22.66 machine cycles
	;; PF0 displayed between clock 68 and 84
	;; PF1 displayed between clock 84 and 116
	;; PF2 displayed between clock 116 and 148

	;; Background
	sta COLUBK		; 3
	;; First left of the screen
	lda fb0 + {1}		; 3
	sta PF0			; 3
	lda fb1 + {1}		; 3
	sta PF1			; 3
	lda fb2 + {1}		; 3
	sta PF2			; 3
	NEXT_BG_LOW
	lda fb3 + {1}		; 3
	sta PF0			; 3
	lda fb4 + {1}		; 3
	sta PF1			; 3
	lda fb5 + {1}		; 3
	sta PF2			; 3
	;; 48 cycles = 144 clocks count
	NEXT_BG_HIGH
	endm

;display_scroll_frame SUBROUTINE
fx_scrollv2_kernel SUBROUTINE
	;; Compute offset text
	lda frame_cnt
	and #$3F		; 64 modulus
	tay
	ldx scroll_table,Y
	stx cur_offset
.offset
	NEXT_BG_COLOR
	sta WSYNC
	sta COLUBK
	dex
	bpl .offset

	NEXT_BG_COLOR
	ldx col_start
LINE_NUM SET 7
	REPEAT 8
	REPEAT TEXT_WIDTH
	stx COLUPF		; 3
	DRAW_ONE_LINE LINE_NUM
	inx
	REPEND
LINE_NUM SET LINE_NUM - 1
	REPEND

	; Displaying blank lines until the end
	sta WSYNC
	sta COLUBK
	lda #$0
	sta PF0
	sta PF1
	sta PF2

;;; Displaying bg colors until the end
	lda #192 - 8*TEXT_WIDTH - 3
	sec
	sbc cur_offset
	tax
.fill_bottom
	NEXT_BG_COLOR
	sta WSYNC
	sta COLUBK
	dex
	bne .fill_bottom	; x value can be > 128 - seen negative

	;; Set background to black at the end of frame
	lda #$00
	sta COLUBK
	inc col_start
	rts

scroll_table
	dc.b $20, $23, $26, $29, $2c, $2f, $32, $34
	dc.b $37, $39, $3b, $3c, $3e, $3f, $3f, $40
	dc.b $40, $40, $3f, $3f, $3e, $3c, $3b, $39
	dc.b $37, $34, $32, $2f, $2c, $29, $26, $23
	dc.b $20, $1d, $1a, $17, $14, $11, $0e, $0c
	dc.b $09, $07, $05, $04, $02, $01, $01, $00
	dc.b $00, $00, $01, $01, $02, $04, $05, $07
	dc.b $09, $0c, $0e, $11, $14, $17, $1a, $1d

alphabet
	;; @ or NULL
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; A
	dc.b %11111100
	dc.b %00010010
	dc.b %00010001
	dc.b %00010010
	dc.b %11111100
	dc.b %00000000
	;; B
	dc.b %11111111
	dc.b %10001001
	dc.b %10001001
	dc.b %10001110
	dc.b %01110000
	dc.b %00000000
	;; C
	dc.b %01111110
	dc.b %10000001
	dc.b %10000001
	dc.b %10000001
	dc.b %01000010
	dc.b %00000000
	;; D
	dc.b %11111111
	dc.b %10000001
	dc.b %10000001
	dc.b %01000010
	dc.b %00111100
	dc.b %00000000
	;; E
	dc.b %11111111
	dc.b %10001001
	dc.b %10001001
	dc.b %10001001
	dc.b %10000001
	dc.b %00000000
	;; F
	dc.b %11111111
	dc.b %00001001
	dc.b %00001001
	dc.b %00001001
	dc.b %00000001
	dc.b %00000000
	;; G
	dc.b %01111110
	dc.b %10000001
	dc.b %10010001
	dc.b %10010001
	dc.b %01110010
	dc.b %00000000
	;; H
	dc.b %11111111
	dc.b %00001000
	dc.b %00001000
	dc.b %00001000
	dc.b %11111111
	dc.b %00000000
	;; I
	dc.b %10000001
	dc.b %10000001
	dc.b %11111111
	dc.b %10000001
	dc.b %10000001
	dc.b %00000000
	;; J
	dc.b %01100000
	dc.b %10000001
	dc.b %10000001
	dc.b %01111111
	dc.b %00000001
	dc.b %00000000
	;; K
	dc.b %11111111
	dc.b %00001000
	dc.b %00010100
	dc.b %00100010
	dc.b %11000001
	dc.b %00000000
	;; L
	dc.b %11111111
	dc.b %10000000
	dc.b %10000000
	dc.b %10000000
	dc.b %10000000
	dc.b %00000000
	;; M
	dc.b %11111111
	dc.b %00001100
	dc.b %00110000
	dc.b %00001100
	dc.b %11111111
	dc.b %00000000
	;; N
	dc.b %11111111
	dc.b %00000110
	dc.b %00011000
	dc.b %01100000
	dc.b %11111111
	dc.b %00000000
	;; O
	dc.b %00111100
	dc.b %01000010
	dc.b %10000001
	dc.b %01000010
	dc.b %00111100
	dc.b %00000000
	;; P
	dc.b %11111111
	dc.b %00001001
	dc.b %00001001
	dc.b %00001001
	dc.b %00000110
	dc.b %00000000
	;; Q
	dc.b %00111100
	dc.b %01000010
	dc.b %10100001
	dc.b %01000010
	dc.b %10111100
	dc.b %00000000
	;; R
	dc.b %11111111
	dc.b %00011001
	dc.b %00101001
	dc.b %01001001
	dc.b %10000110
	dc.b %00000000
	;; S
	dc.b %01000110
	dc.b %10001001
	dc.b %10001001
	dc.b %10001001
	dc.b %01110010
	dc.b %00000000
	;; T
	dc.b %00000001
	dc.b %00000001
	dc.b %11111111
	dc.b %00000001
	dc.b %00000001
	dc.b %00000000
	;; U
	dc.b %01111111
	dc.b %10000000
	dc.b %10000000
	dc.b %10000000
	dc.b %01111111
	dc.b %00000000
	;; V
	dc.b %00000111
	dc.b %00111000
	dc.b %11000000
	dc.b %00111000
	dc.b %00000111
	dc.b %00000000
	;; W
	dc.b %00111111
	dc.b %11000000
	dc.b %00110000
	dc.b %11000000
	dc.b %00111111
	dc.b %00000000
	;; X
	dc.b %10000001
	dc.b %01100110
	dc.b %00011000
	dc.b %01100110
	dc.b %10000001
	dc.b %00000000
	;; Y
	dc.b %00000011
	dc.b %00001100
	dc.b %11110000
	dc.b %00001100
	dc.b %00000011
	dc.b %00000000
	;; Z
	dc.b %11000001
	dc.b %10100001
	dc.b %10011001
	dc.b %10000101
	dc.b %10000011
	dc.b %00000000
	;; [
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; \
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; ]
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; ^
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; _
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; <space>
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; !
	dc.b %00000000
	dc.b %00000000
	dc.b %10111111
	dc.b %00000111
	dc.b %00000000
	dc.b %00000000
	;; "
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; #
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; $
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; %
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; &
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; '
	dc.b %00000000
	dc.b %00000100
	dc.b %00000011
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; (
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; )
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; *
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; +
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; ,
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; -
	dc.b %00000000
	dc.b %00000000
	dc.b %00010000
	dc.b %00010000
	dc.b %00000000
	dc.b %00000000
	;; .
	dc.b %00000000
	dc.b %00000000
	dc.b %11000000
	dc.b %11000000
	dc.b %00000000
	dc.b %00000000
	;; /
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; 0
	dc.b %01111110
	dc.b %11100001
	dc.b %10011001
	dc.b %10000111
	dc.b %01111110
	dc.b %00000000
	;; 1
	dc.b %00000000
	dc.b %00000100
	dc.b %10000010
	dc.b %11111111
	dc.b %10000000
	dc.b %00000000
	;; 2
	dc.b %11000110
	dc.b %10100001
	dc.b %10010001
	dc.b %10001001
	dc.b %10000110
	dc.b %00000000
	;; 3
	dc.b %10000001
	dc.b %10001001
	dc.b %10001001
	dc.b %10001001
	dc.b %01110110
	dc.b %00000000
	;; 4
	dc.b %01100000
	dc.b %01011000
	dc.b %01000110
	dc.b %11100001
	dc.b %01000000
	dc.b %00000000
	;; 5
	dc.b %01001111
	dc.b %10001001
	dc.b %10001001
	dc.b %10001001
	dc.b %01110001
	dc.b %00000000
	;; 6
	dc.b %01111100
	dc.b %10010010
	dc.b %10010001
	dc.b %10010001
	dc.b %01100000
	dc.b %00000000
	;; 7
	dc.b %00000001
	dc.b %11000001
	dc.b %00110001
	dc.b %00001101
	dc.b %00000011
	dc.b %00000000
	;; 8
	dc.b %01110110
	dc.b %10001001
	dc.b %10001001
	dc.b %10001001
	dc.b %01110110
	dc.b %00000000
	;; 9
	dc.b %00000110
	dc.b %10001001
	dc.b %01001001
	dc.b %00101001
	dc.b %00011110
	dc.b %00000000
	;; :
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; ;
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; <
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; =
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; >
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	;; ?
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000

scroll_background
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $04, $04, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $04
	dc.b $04, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $04, $04, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $04, $04, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $04, $04, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $04, $04, $00, $00, $00
	dc.b $00, $04, $04, $00, $00, $04, $04, $00
	dc.b $00, $04, $04, $00, $00, $04, $04, $00
	dc.b $00, $00, $00, $04, $04, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $04, $04
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $04, $04, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
scroll_bg_trans
	dc.b $00, $03, $06, $09, $0c, $0f, $12, $15
	dc.b $18, $1b, $1e, $20, $23, $26, $28, $2a
	dc.b $2d, $2f, $31, $33, $35, $36, $38, $39
	dc.b $3b, $3c, $3d, $3e, $3e, $3f, $3f, $3f
	dc.b $40, $3f, $3f, $3f, $3e, $3e, $3d, $3c
	dc.b $3b, $39, $38, $36, $35, $33, $31, $2f
	dc.b $2d, $2a, $28, $26, $23, $20, $1e, $1b
	dc.b $18, $15, $12, $0f, $0c, $09, $06, $03
scroll_bg_scale
	dc.b $40, $41, $43, $44, $46, $47, $49, $4a
	dc.b $4c, $4e, $4f, $51, $52, $54, $55, $57
	dc.b $58, $59, $5b, $5c, $5e, $5f, $60, $62
	dc.b $63, $64, $66, $67, $68, $69, $6a, $6c
	dc.b $6d, $6e, $6f, $70, $71, $72, $73, $74
	dc.b $75, $76, $76, $77, $78, $79, $79, $7a
	dc.b $7b, $7b, $7c, $7c, $7d, $7d, $7e, $7e
	dc.b $7e, $7f, $7f, $7f, $7f, $7f, $7f, $7f
	dc.b $80, $7f, $7f, $7f, $7f, $7f, $7f, $7f
	dc.b $7e, $7e, $7e, $7d, $7d, $7c, $7c, $7b
	dc.b $7b, $7a, $79, $79, $78, $77, $76, $76
	dc.b $75, $74, $73, $72, $71, $70, $6f, $6e
	dc.b $6d, $6c, $6a, $69, $68, $67, $66, $64
	dc.b $63, $62, $60, $5f, $5e, $5c, $5b, $59
	dc.b $58, $57, $55, $54, $52, $51, $4f, $4e
	dc.b $4c, $4a, $49, $47, $46, $44, $43, $41
	dc.b $40, $3e, $3c, $3b, $39, $38, $36, $35
	dc.b $33, $31, $30, $2e, $2d, $2b, $2a, $28
	dc.b $27, $26, $24, $23, $21, $20, $1f, $1d
	dc.b $1c, $1b, $19, $18, $17, $16, $15, $13
	dc.b $12, $11, $10, $0f, $0e, $0d, $0c, $0b
	dc.b $0a, $09, $09, $08, $07, $06, $06, $05
	dc.b $04, $04, $03, $03, $02, $02, $01, $01
	dc.b $01, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $01, $01, $01, $02, $02, $03, $03, $04
	dc.b $04, $05, $06, $06, $07, $08, $09, $09
	dc.b $0a, $0b, $0c, $0d, $0e, $0f, $10, $11
	dc.b $12, $13, $15, $16, $17, $18, $19, $1b
	dc.b $1c, $1d, $1f, $20, $21, $23, $24, $26
	dc.b $27, $28, $2a, $2b, $2d, $2e, $30, $31
	dc.b $33, $35, $36, $38, $39, $3b, $3c, $3e

scroll_text
	dc.b " FLUSH IS PROUD TO PRESENT ROTOR RELEASED AT THE SILLYVENTURE 2K16! !! "
	dc.b "MUSIC BY GLAFOUK .. "
	dc.b "GFX BY G012 - GLAFOUK - P0KE .. "
	dc.b "FX BY FLEWWW - G012 - P0KE .. "
	dc.b "SPECIAL THANKS TO KYLEARAN FOR TIATRACKER AND KK FOR K65 .. "
	dc.b "AND GLAFOUK SAYS GNAH! .. "
	dc.b "GREETZ TO SECTOR ONE - TRAKTOR - XMEN - RAZOR 1911 - LNX - BLABLA - "
	dc.b "POO BRAIN - INSANE - TJOPPEN - CTRL ALT TEST - RED SECTOR INC - TMP - DUNE - XAYAX "
	dc.b "JAC - KK - KYLEARAN - SIR GARBAGE TRUCK ......... "
