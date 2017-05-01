	include "tunnel_tables.asm"

N_VARIANTS = 14
TUNSPRHEIGHT  EQU     #36

fx_update SUBROUTINE
	ldx tunvar
	lda fxseq_tbhi,X
	sta tuntbl
	lda fxseq_tblo,X
	sta tuntbl+1
	lda fxseq_txhi,X
	sta tuntxt
	lda fxseq_txlo,X
	sta tuntxt+1

	txa
	asl
	tax
	lda fxseq_time,X
	sta tuntm
	inx
	lda fxseq_time,X
	sta tuntm+1

	rts

fx_tunnel_setup SUBROUTINE
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

	lda #$00
	sta tunfc
	sta tunfc+1
	sta tunvar
	sta tunx
	jsr fx_update

;sprite
    ldx #0
    lda rotor_tbl_lo,x
    sta tunptr
    adc TUNSPRHEIGHT
    sta tunptr+2
    adc TUNSPRHEIGHT
    sta tunptr+4

    lda rotor_tbl_lo+3,x
    sta tunptr+6
    adc TUNSPRHEIGHT
    sta tunptr+8
    adc TUNSPRHEIGHT
    sta tunptr+10

    lda rotor_tbl_hi,x
    sta tunptr+1
    sta tunptr+3
    sta tunptr+5
    lda rotor_tbl_hi+3,x
    sta tunptr+7
    sta tunptr+9
    sta tunptr+11
    
    lda #$0
    sta COLUP0
    sta COLUP1
    lda #%011
    sta NUSIZ0
    sta NUSIZ1
    sta VDELP0
    sta VDELP1
    sta WSYNC
    SLEEP 37
    sta RESP0       ; trigger le point d'a partir duquel le sprite sera affiché
    sta RESP1       ; same same
    LDA #$10        ; décalage hmp0
    STA HMP0
    LDA #$20
    STA HMP1
    STA WSYNC
    STA HMOVE

	rts

    .align 256

fx_tunnel_kernel SUBROUTINE
	sta WSYNC		; Finish line 38
	ldx #191		; lines from 191 to 0
.disp_lines
	txa
	tay
	lda (tuntbl),Y
	cmp #$ff		; infinity zone
	beq .black
	and #$80
	bne .black0
	lda (tuntbl),Y
	clc
	adc tunx
	tay
	lda (tuntxt),Y
	jmp .kern_next
.black0
	lda #$00
.kern_next
	sta WSYNC
	sta COLUBK
	dex
	txa
	cmp #$ff
	bne .disp_lines
	lda #$00
	sta COLUBK
	rts

.black ; draw sprite
    txa
    pha
    lda #0
    sta WSYNC
    sta COLUBK
	lda #$66
	sta COLUPF
    lda #$FC
	sta PF2
    SLEEP 44
    lda #0
    ldy #TUNSPRHEIGHT
.spritek
    sty tuntmp       ;3   
    lda (tunptr+$0),y  ;5        
    sta GRP0        ;3
    lda (tunptr+$2),y  ;5       
    sta GRP1        ;3  

    ;sty COLUP0
    sty COLUPF
    sty COLUPF
    nop

    ;cpy #1
    ;beq .spriteout
    ;nop
    ;nop

    lda (tunptr+$4),y  ;5        
    sta GRP0        ;3        
    
    lda (tunptr+$6),y  ;5        
    sta tuntmp+1       ;3     

    lax (tunptr+$a),y  ;5        
    lda (tunptr+$8),y  ;5        
    ldy tuntmp+1       ;3      
    sty GRP1        ;3        
    sta GRP0        ;3        
    stx GRP1        ;3        
    sta GRP0        ;3        
    ldy tuntmp       ;3
    dey             ;2
    bne .spritek     ;2
.spriteout
    pla
    clc
    sbc #TUNSPRHEIGHT+1
    tax
    lda #$0
    sta PF2
    sta GRP0
    sta GRP1
    sta GRP0
    sta GRP1
	lda #$FF        ; Playfield collor (yellow-ish)
	sta COLUPF
    jmp .kern_next


fx_tunnel_overscan SUBROUTINE
	lda tunfc
	clc
	adc #1
	sta tunfc
	lda tunfc+1
	adc #0
	sta tunfc+1

	;; Last variant
	lda tunvar
	cmp #N_VARIANTS-1
	beq .next

	;; compare frame counter to next variant time
	lda tunfc
	cmp tuntm
	bne .next
	lda tunfc+1
	cmp tuntm+1
	bne .next

	inc tunvar
	jsr fx_update
.next
	lda tunfc
	and #$01
	bne .next2
	inc tunx
.next2
	rts

fx_tunnel_vblank SUBROUTINE
	rts

fxseq_tbhi
	dc.b #<tunnel_table1
	dc.b #<tunnel_table1
	dc.b #<tunnel_table2
	dc.b #<tunnel_table3
	dc.b #<tunnel_table3
	dc.b #<tunnel_table2
	dc.b #<tunnel_table1
	dc.b #<tunnel_table2
	dc.b #<tunnel_table3
	dc.b #<tunnel_table1
	dc.b #<tunnel_table2
	dc.b #<tunnel_table3
	dc.b #<tunnel_table1
	dc.b #<tunnel_table2

fxseq_tblo
	dc.b #>tunnel_table1
	dc.b #>tunnel_table1
	dc.b #>tunnel_table2
	dc.b #>tunnel_table3
	dc.b #>tunnel_table3
	dc.b #>tunnel_table2
	dc.b #>tunnel_table1
	dc.b #>tunnel_table2
	dc.b #>tunnel_table3
	dc.b #>tunnel_table1
	dc.b #>tunnel_table2
	dc.b #>tunnel_table3
	dc.b #>tunnel_table1
	dc.b #>tunnel_table2

fxseq_txhi
	dc.b #<tunnel_texture1
	dc.b #<tunnel_texture2
	dc.b #<tunnel_texture3
	dc.b #<tunnel_texture2
	dc.b #<tunnel_texture1
	dc.b #<tunnel_texture2
	dc.b #<tunnel_texture1
	dc.b #<tunnel_texture2
	dc.b #<tunnel_texture3
	dc.b #<tunnel_texture1
	dc.b #<tunnel_texture2
	dc.b #<tunnel_texture3
	dc.b #<tunnel_texture1
	dc.b #<tunnel_texture2

fxseq_txlo
	dc.b #>tunnel_texture1
	dc.b #>tunnel_texture2
	dc.b #>tunnel_texture3
	dc.b #>tunnel_texture2
	dc.b #>tunnel_texture1
	dc.b #>tunnel_texture2
	dc.b #>tunnel_texture1
	dc.b #>tunnel_texture2
	dc.b #>tunnel_texture3
	dc.b #>tunnel_texture1
	dc.b #>tunnel_texture2
	dc.b #>tunnel_texture3
	dc.b #>tunnel_texture1
	dc.b #>tunnel_texture2

fxseq_time
	dc.w $180, $300, $3c0, $480, $540, $600, $660, $6c0
	dc.w $720, $780, $7e0, $840, $8a0, $900, $960
