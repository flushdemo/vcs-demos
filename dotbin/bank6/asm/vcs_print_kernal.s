	.include "globals.inc"
	.include "banksetup.inc"

	.import _vcs_print_font	; Fonts table defined in C code
	.importzp _fx_data 	; Space for FX Data

	.export _vcs_print_kernal
	.export _init_vcs_print_kernal

.segment CODE_SEGMENT
;;; Fetches the nth character in the string pointed by `ptr1`
;;; Stores in _fx_data array of pointers
.macro	fetch_char	n	; Fetch the n'th character
.scope
	dex			;  2
	bpl char		;  2-3
blank:
	txa			;  2
	cmp #$ff		;  2
	beq cursor		;  2-3
	lda #0			;  2
	nop			;  2
	jmp cont		;  3
cursor:
	lda tmp3		;  3
	lda tmp3		;  3
cont:
	sta _fx_data + 2*n	;  3
	jmp end			;  3
char:
	ldy #n			;  2
	lda (ptr1),Y		;  5
	asl			;  2
	asl			;  2
	asl			;  2
	sta _fx_data + 2*n	;  3
	nop			;  2
end:
.endscope
.endmacro			; 21

.proc	_init_vcs_print_kernal
	;; Initialize pointers to the font table
	lda #>_vcs_print_font	;  2
	ldx #23
loop:	sta _fx_data,X
	dex
	dex
	bpl loop
	jmp _bankReturn
.endproc

.proc	_vcs_print_kernal
;;; High byte in X
;;; Low byte in A
;;; L44
	;; Store address of text to display
	popax
	sta ptr1
	stx ptr1+1
	;; Characters count
	popax
	sta tmp2
	;; Cursor
	popax
	sta tmp3
	;; Lines count
	popax
	sta tmp1
	;; Offset
	popax
	sta tmp4
	;; Update music during vblank
	jsr _wait_vblank
	ldx tmp4
@offset:
	sta WSYNC
	dex
	bne @offset
	sta WSYNC

;;; L45: Position the sprites
;;; 12*8 = 96 pixels for the text
;;; i.ie 32 pixels on each side (160 - 96)/2
;;; +68 HBLANK = 100 pixels for RESP0
	ldx #6  		; 2 - Approx 128 pixels / 15
posit:	dex			; 2
	bne posit		; 2** (3 if branching)
	sta RESP0		; 3 34 (2 + 5*(2+3) + 4 + 3)
	;; 102 pixels - 68 = 34 ; -> 39 observerd on Stella
	nop
	sta RESP1
	lda #$70		; -> now 100 pixels
	sta HMP0
	lda #$60
	sta HMP1
	sta WSYNC
	sta HMOVE

;;; L46: 4 lines to setup the 12 characters to display
line:	ldx tmp2
	.repeat 12, I
	fetch_char I
	.endrepeat
	stx tmp2
	;; Moving characters 8 pixels to the right
	lda #$80
	sta HMP0
	lda #$80
	sta HMP1
	ldy #0

;;; Exploiting a bug to move the sprites of +8 pixels
;;; This happens when writing HMOVE at the end of the scanline.
;;; L54: Display 2*8 lines
txt_ln:	;; odd lines - Shifted by 8 pix to the right -> 108
	sta WSYNC		; 3  78
	sta HMOVE 		; 3   3
	lda (_fx_data+2),Y	; 5   8
	sta GRP0		; 3  11
	lda (_fx_data+6),Y	; 5  16
	sta GRP1		; 3  19
	lda (_fx_data+22),Y	; 5  24
	tax			; 2  26 78
	.repeat 3
	nop
	.endrepeat	     	; 6  32
	lda (_fx_data+10),Y	; 5  37
	sta GRP0		; 3  40 120
	lda (_fx_data+14),Y	; 5  45
	sta GRP1		; 3  48
	lda (_fx_data+18),Y	; 5  53
	sta GRP0		; 3  56
	stx GRP1		; 3  59 154
	sta HMCLR	     	; 3  62
	.repeat 4
	nop
	.endrepeat	        ; 8  70
	sta HMOVE		; 3  73 - End of scanline
	;; even lines
	;; Moving characters 8 pixels to the left
	lda (_fx_data+0),Y	; 5   2
	sta GRP0		; 3   5
	lda (_fx_data+4),Y	; 5  10
	sta GRP1		; 3  13
	lda (_fx_data+20),Y	; 5  18
	tax			; 2  20
	;; Moving characters 8 pixels to the right
	lda #$80		; 2  22
	sta HMP0		; 3  25
	lda #$80		; 2  27
	sta HMP1		; 3  30
	;; Updating sprites graphics
	lda (_fx_data+8),Y	; 5  35
	sta GRP0		; 3  38
	lda (_fx_data+12),Y	; 5  43
	sta GRP1		; 3  46
	lda (_fx_data+16),Y	; 5  51
	sta GRP0		; 3  54
	stx GRP1		; 3  57
	;; looping logic
	iny			; 2  59
	tya			; 2  61
	cmp #8			; 2  63
	bne txt_ln		; 4(2+2) 67

	dec tmp1
	beq end

	;; Fetching next line of text
	clc
	lda ptr1
	adc #12
	sta ptr1
	lda ptr1+1
	adc #0
	sta ptr1+1
	jmp line

end:
	lda #$0
	sta GRP0
	sta GRP1
	jmp _bankReturn
.endproc
