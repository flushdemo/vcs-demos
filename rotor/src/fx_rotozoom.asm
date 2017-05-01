	include "pic_invader.asm"
	include "pic_atari.asm"
	include "sincos_tables_0.5.asm"
	include "sincos_tables_0.99.asm"

;;; Timer counter to display lines at good time
TIM_PIX_BLOCK = 9	; 9 * 64 cycles = 576

;;; Timing for different parts of the FX
TIME_FX2 = 180
TIME_FX3 = 360
TIME_FX4 = 990
TIME_FX5 = 1035
TIME_FX6 = 1215

;;;;;;;;;;;;;;;
;
; FX Setup
;
;;;;;;;;;;;;;;;

fx_rotozoom_setup SUBROUTINE
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
	lda #$01        ; Ensure we will duplicate (and not reflect) PF
	sta CTRLPF

	;; Initialize rotozoom vector & initial position
	;; 4 + 4 bits needed to address 16 pixels on x and 16 on y
	lda #0
	sta rec_x
	sta rec_y
	sta angle		; This is a counter
	sta fx_counter
	sta angle_delay		; When starting FX the picture doesn't move
	sta trans_delay
	sta angle_counter	; Initialize counters
	sta trans_counter
	lda #72			; 24 * 3
	sta fb_pt		; Initialize fb_pt at end of framebuffer

	;; Picture to display
	lda #<pic_invader
	sta cur_pic
	lda #>pic_invader
	sta cur_pic+1

	;; sin & cos tables to use
	lda #<sin_table_0.5
	sta cur_sin
	lda #>sin_table_0.5
	sta cur_sin+1
	lda #<cos_table_0.5
	sta cur_cos
	lda #>cos_table_0.5
	sta cur_cos+1

	lda #<(roto_fxvar1-1)
	sta roto_fxvar
	lda #>(roto_fxvar1-1)
	sta roto_fxvar+1
	rts

;;;;;;;;;;;;;;;;
;
; FX Kernel
;
;;;;;;;;;;;;;;;;

;;; Update playfield color
	mac UPDATE_COLOR
	clc
	lda pf_hue
	adc #$02
	sta pf_hue
	and #$f0
	sta rz_tmp

	lda pf_dir
	beq .descend
	clc
	lda pf_lum
	adc #$02
	sta pf_lum
	cmp #$fe
	bne .end_add
	lda #0
	sta pf_dir
	jmp .end_add
.descend
	sec
	lda pf_lum
	sbc #$02
	sta pf_lum
	cmp #$20
	bne .end_add
	lda #1
	sta pf_dir
.end_add
	REPEAT 4
	lsr
	REPEND

	ora rz_tmp
	sta COLUPF
	endm

fx_rotozoom_kernel2 SUBROUTINE	; scanline 0 - scan cycle 41
	;; 37 vblank lines * 76 machine cycles - 41 cycles = 2771 cycles
	REPEAT 5
	jsr	compute_next_byte
	REPEND
        ;; set line_pt fo start of frame_buffer
        lda     #<frame_buffer
        sta     line_pt
        lda     #>frame_buffer
        sta     line_pt+1

	;jsr	WaitForVBlankEnd
	;jsr	display_frame
	;jsr	WaitForDisplayEnd
	; 30 overscan cycles to spend there = 2280 cycles
	UPDATE_COLOR
	REPEAT 5
	jsr	compute_next_byte
	REPEND
	;jmp	MainLoop
    rts

fx_rotozoom_vblank SUBROUTINE
	REPEAT 6
	jsr	compute_next_byte
	REPEND
        ;; set line_pt fo start of frame_buffer
        lda     #<frame_buffer
        sta     line_pt
        lda     #>frame_buffer
        sta     line_pt+1
    rts

fx_rotozoom_overscan SUBROUTINE
	UPDATE_COLOR
	REPEAT 4
	jsr	compute_next_byte
	REPEND
    rts

;;;;;;;;;;;;;;
;
; FX Code
;
;;;;;;;;;;;;;;


;;; Retrieves a bit from pic_invader bitmap according to pix_x and pix_y
	mac GET_BIT
	;; Texture is a 16x16 bitmap (1 byte per pixel)
	;; This means 4 first bytes of Y || 4 last bytes of X
	;; is a pointer to the byte representing the bit

	;; Besides, pix_x and pix_y are fixed decimal number
	;; where the 4 highest bits are the integer part.
	lda pix_y		; 3 cycles
	and #$f0		; 2
	sta rz_tmp		; 3
	lda pix_x		; 3
	REPEAT 4
	lsr			; 2*4
	REPEND
	ora rz_tmp		; 3
	tay			; 2 - Index stored in X
	lda (cur_pic),Y	; 5 or 6
	;; For a total of 29 cycles
	endm

;;; Compute new value of pix_x and pix_y
	mac NEXT_BIT
	;; Simple 8 bits addition
	clc			; 2 cycles
	lda vec_x		; 3
	adc pix_x		; 3
	sta pix_x		; 3
	clc			; 2
	lda vec_y		; 3
	adc pix_y		; 3
	sta pix_y		; 3
	;; For a total of 22 cycles
	endm

roto_fxvar1 SUBROUTINE
	lda #<TIME_FX2		; 2
	cmp fx_counter		; 3
	bne .next		; 3
	lda #>TIME_FX2		; 2
	cmp fx_counter + 1	; 3
	bne .next		; 3
	lda #2
	sta trans_delay
	sta trans_counter
	lda #<(roto_fxvar2-1)
	sta roto_fxvar
	lda #>(roto_fxvar2-1)
	sta roto_fxvar+1
.next
	rts

roto_fxvar2 SUBROUTINE
	lda #<TIME_FX3		; 2
	cmp fx_counter		; 3
	bne .next		; 3
	lda #>TIME_FX3		; 2
	cmp fx_counter + 1	; 3
	bne .next		; 3
	lda #1
	sta trans_delay
	sta trans_counter
	lda #2
	sta angle_delay
	sta angle_counter
	lda #<(roto_fxvar3-1)
	sta roto_fxvar
	lda #>(roto_fxvar3-1)
	sta roto_fxvar+1
.next
	rts

roto_fxvar3 SUBROUTINE
	lda #<TIME_FX4		; 2
	cmp fx_counter		; 3
	bne .next		; 3
	lda #>TIME_FX4		; 2
	cmp fx_counter + 1	; 3
	bne .next		; 3
	;; sin & cos tables to use
	lda #<sin_table_0.99
	sta cur_sin
	lda #>sin_table_0.99
	sta cur_sin+1
	lda #<cos_table_0.99
	sta cur_cos
	lda #>cos_table_0.99
	sta cur_cos+1
	lda #<(roto_fxvar4-1)
	sta roto_fxvar
	lda #>(roto_fxvar4-1)
	sta roto_fxvar+1
.next
	rts

roto_fxvar4 SUBROUTINE
	lda #<TIME_FX5		; 2
	cmp fx_counter		; 3
	bne .next		; 3
	lda #>TIME_FX5		; 2
	cmp fx_counter + 1	; 3
	bne .next		; 3
	lda #<pic_atari
	sta cur_pic
	lda #>pic_atari
	sta cur_pic+1
	lda #<(roto_fxvar5-1)
	sta roto_fxvar
	lda #>(roto_fxvar5-1)
	sta roto_fxvar+1
.next
	rts

roto_fxvar5 SUBROUTINE
	lda #<TIME_FX6		; 2
	cmp fx_counter		; 3
	bne .next		; 3
	lda #>TIME_FX6		; 2
	cmp fx_counter + 1	; 3
	bne .next		; 3
	;; sin & cos tables to use
	lda #<sin_table_0.5
	sta cur_sin
	lda #>sin_table_0.5
	sta cur_sin+1
	lda #<cos_table_0.5
	sta cur_cos
	lda #>cos_table_0.5
	sta cur_cos+1
	lda #<(roto_fxvar6-1)
	sta roto_fxvar
	lda #>(roto_fxvar6-1)
	sta roto_fxvar+1
.next
	rts

roto_fxvar6 SUBROUTINE
	rts

;;; Update FX variant according to time position
select_fx SUBROUTINE
	lda roto_fxvar+1
	pha
	lda roto_fxvar
	pha
	rts

;;; Updates the rectangle window to project on the screen
;;; Performs rotation and translation
	mac UPDATE_RECT
	;; Set rotation angle - if angle_counter is 0
	dec angle_counter
	bne .end_angle
	lda angle_delay
	sta angle_counter
	inc angle		; 5 - Prepare for next cos/sin to fetch
.end_angle
	ldy angle		; 3
	lda (cur_cos),Y		; 3
	sta vec_x		; 3
	lda (cur_sin),Y		; 3
	sta vec_y		; 3
	;; Increment rec_x
	dec trans_counter
	bne .end_trans
	lda trans_delay
	sta trans_counter
	lda rec_x
	clc
	adc #1
	ora #$0f
	sta rec_x
.end_trans
	;; increment fx_counter
	clc
	lda fx_counter
	adc #1
	sta fx_counter
	lda fx_counter + 1
	adc #0
	sta fx_counter + 1
	endm

compute_next_byte SUBROUTINE
	;; Switching routine according to fb_byte
	lda fb_byte		; 3
	cmp #1			; 2
	bne .next_cmp		; 2
	jmp .p1_byte		; 3
.next_cmp
	cmp #2			; 2
	bne .p0_byte		; 2
	jmp .p2_byte		; 3

.p0_byte
	;; Switching cost is 11 cycles
	;; New frame initialization block
	;; Checking for end of frame
	lda #72			; 2 - 24 lines * 3 bytes/line
	cmp fb_pt		; 3
	bne .compute_p0		; 2

	jsr select_fx		; Update FX to play if required
	UPDATE_RECT		; Update rectangle to project

	lda rec_x		; 3
	sta line_x		; 3
	;; copy rec_y to line_y
	lda rec_y		; 3
	sta line_y		; 3
	;; Next byte to write is first frame_buffer byte
	lda #0			; 2
	sta fb_pt		; 3 - Bytes to be computed

.compute_p0
	;; Initialize pix_x & pix_y indexes
	lda line_x		; 3
	sta pix_x		; 3
	lda line_y		; 3
	sta pix_y		; 3
	;; First byte: 4 last bits reverse order
	GET_BIT			; 28
	and #$10		; 2 cycles
	sta bits_tmp + 0	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$20		; 2
	sta bits_tmp + 1	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$40		; 2
	sta bits_tmp + 2	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$80		; 2
	ora bits_tmp + 0	; 3
	ora bits_tmp + 1	; 3
	ora bits_tmp + 2	; 3
	;; Following the fb_pt byte
	ldx fb_pt		; 3
	sta frame_buffer,X	; 5
	inc fb_pt		; 5
	NEXT_BIT		; 22
	inc fb_byte		; 5
	rts			; 6
	;; subtotal is 262
	;; Total p0_byte is 317

.p1_byte
	;; Switching cost is 10 cycles
	;; Second byte: 8 bits normal order
	GET_BIT			; 28
	and #$80		; 2 cycles
	sta bits_tmp + 0	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$40		; 2
	sta bits_tmp + 1	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$20		; 2
	sta bits_tmp + 2	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$10		; 2
	sta bits_tmp + 3	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$08		; 2 cycles
	sta bits_tmp + 4	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$04		; 2
	sta bits_tmp + 5	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$02		; 2
	sta bits_tmp + 6	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$01		; 2
	ora bits_tmp + 0	; 3
	ora bits_tmp + 1	; 3
	ora bits_tmp + 2	; 3
	ora bits_tmp + 3	; 3
	ora bits_tmp + 4	; 3
	ora bits_tmp + 5	; 3
	ora bits_tmp + 6	; 3
	;; Following the fb_pt byte
	ldx fb_pt		; 3
	sta frame_buffer,X	; 5
	inc fb_pt		; 5
	NEXT_BIT		; 22
	inc fb_byte		; 5
	rts			; 6
	;; Total for p1 is 492 cycles

.p2_byte
	;; Switching cost is 14 cycles
	;; Third byte: 8 bits reverse order
	GET_BIT			; 28
	and #$01		; 2 cycles
	sta bits_tmp + 0	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$02		; 2
	sta bits_tmp + 1	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$04		; 2
	sta bits_tmp + 2	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$08		; 2
	sta bits_tmp + 3	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$10		; 2 cycles
	sta bits_tmp + 4	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$20		; 2
	sta bits_tmp + 5	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$40		; 2
	sta bits_tmp + 6	; 3
	NEXT_BIT		; 22
	GET_BIT			; 28
	and #$80		; 2
	ora bits_tmp + 0	; 3
	ora bits_tmp + 1	; 3
	ora bits_tmp + 2	; 3
	ora bits_tmp + 3	; 3
	ora bits_tmp + 4	; 3
	ora bits_tmp + 5	; 3
	ora bits_tmp + 6	; 3
	;; Following the fb_pt byte
	ldx fb_pt		; 3
	sta frame_buffer,X	; 5
	inc fb_pt		; 5
	NEXT_BIT		; 22
	lda #0			; 2
	sta fb_byte		; 3
	;; subtotal 490 (including switching)

	;; Going to next line
	sec			; 2
	lda line_x		; 3
	sbc vec_y		; 3
	sta line_x		; 3
	clc			; 2
	lda line_y		; 3
	adc vec_x		; 3
	sta line_y		; 3
	;; subtotal is 22
	;; End of p2_byte processing

	rts			; 6
	;; Total p2_byte is 518

;;; End of compute_next_byte

fx_rotozoom_kernel SUBROUTINE

	sta WSYNC		; Consume first line heavily started
.draw_lines
	ldy #0			; 2
	lda (line_pt),Y		; 5 cycles
	sta PF0			; 3
	iny			; 2
	lda (line_pt),Y		; 5
	sta PF1			; 3
	iny			; 2
	lda (line_pt),Y		; 5
	sta PF2			; 3
	iny			; 2
	;; Preparing for next line
	lda #3			; 2
	clc			; 2
	adc line_pt		; 3
	sta line_pt		; 3
	;; 42 cycles

	;; Use timer to interrupt after 76*8-(42+30) = 536 cycles
        lda #TIM_PIX_BLOCK	; 2
        sta TIM64T		; 3
	jsr compute_next_byte	; 6
.wait_for_timer
        lda INTIM		; 3
        bne .wait_for_timer	; 3

	lda #frame_buffer+72	; 4 (24*3 bytes)
	cmp line_pt		; 4
	sta WSYNC               ; 3
	bne .draw_lines		; 2
	;; subtotal 30 cycles

	; Displaying blank lines in the overscan
	lda #$0
	sta PF0
	sta PF1
	sta PF2
        lda #$04
        sta TIM8T
	rts
