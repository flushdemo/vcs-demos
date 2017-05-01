.include "globals.inc"
.include "banksetup.inc"
.include "song_player.inc"

.importzp _fx_data      ; Space for FX Data
.export _fx_pf_setup
.export _fx_pf_kernel

ss_fxtime   	= _fx_data                                                                                        
ss_fxtimend 	= _fx_data+2                                                                                      
ss_fxtimebc 	= _fx_data+4                                                                                      
ss_scrinpos 	= _fx_data+6
ss_inst     	= _fx_data+8
ss_tblcl   	= _fx_data+10                                                                                     
ss_doloadscreen   = _fx_data+12  
ss_ptr      	= _fx_data+13  

.segment CODE_SEGMENT

_fx_pf_setup:
                lda #0
                sta ss_fxtime
                sta ss_fxtimend
                sta ss_fxtimebc
                sta ss_scrinpos
                sta ss_inst
                sta ss_tblcl
                sta ss_doloadscreen
                sta ss_ptr
                sta CTRLPF
                sta COLUBK
                lda #$2e
                sta COLUPF
                jsr ss_loadscreen                
                rts

_fx_pf_kernel:  
                lda ss_doloadscreen
                beq @noloadscreen
                dec ss_doloadscreen
                jsr ss_loadscreen
@noloadscreen:
                jsr _wait_vblank
                ldy #7
@fewemptylines:                
                sta WSYNC
                dey
                bne @fewemptylines

                lda #0 
                ldy #39
@ss_Draw_Picture:            
		        ldx #6
@ss_catline:
                lda (ss_ptr+$0),Y
                sta PF0
                lda (ss_ptr+$2),Y
                sta PF1
                lda (ss_ptr+$4),Y
                sta PF2
                lda (ss_ptr+$6),Y 
                sta PF0
                lda (ss_ptr+$8),Y
                sta PF1
                lda (ss_ptr+$a),Y
                sta PF2
                sta WSYNC

                dex
                bne @ss_catline
                
                dey
                bne @ss_Draw_Picture

                lda #0
                sta PF0
                sta PF1
                sta PF2
                
@Overscan:      inc ss_fxtime
                lda ss_fxtime
                cmp $05 
                bpl @resetss_fxtime
                rts
                
@resetss_fxtime:        
                
                inc ss_fxtimebc
                lda ss_fxtimebc
                cmp $02 
                bpl @mefin
                lda #0
                sta ss_fxtime
                rts
@mefin:
                ;jsr ss_loadscreen
                inc ss_doloadscreen
                lda #0
                sta ss_fxtimebc
                inc ss_fxtimend
                lda ss_fxtimend
                cmp $5             ;$5
                beq @thefin
                rts
@thefin:                
                rts
                
ss_loadscreen:
                lda _tt_cur_ins_c1
                cmp ss_inst
                beq @skippos
                sta ss_inst     
                inc ss_scrinpos

		        inc ss_tblcl
                ldy ss_tblcl
                lda ss_col,y
                cmp #255
                bne @chgcol
                ldy #0
                sty ss_tblcl
                lda ss_col,y
@chgcol:        sta COLUPF 

@skippos:       ldy ss_scrinpos
                ldx @ss_anim,y
                cpx #255
                beq @fin

                txa
                clc
                adc #16-14-1+$B0 ; 16 - <number of screens> - 1 (cause ss_anim counts from 1) + $B0 (bank 4)
                sta ss_ptr+1

                ldx #2
                ldy #2

@ss_setpointer:                
                clc
                lda ss_ptr-$2,y
                adc #40
                sta ss_ptr,y
                lda ss_ptr-$1,y
                adc #0
                sta ss_ptr+$1,y
                iny
                iny
                inx
                cpx #7
                bmi @ss_setpointer
                rts
@fin:              
                lda #0
                sta ss_scrinpos  
                jmp ss_loadscreen
                
@ss_anim:       .byte 1,2,3,4,3,4,5,6,5,6,5,6,5,6,7,8,8,8,8,9,13,14,14,14,14,10,11,12,13,10,11,12,14,13,12,6,5,6,5,2,1,255



    .align 256
                .include "ss_00.inc"
ss_col:	.byte $2e,$3e,$4e,$5e,$6e,255
    .align 256
                .include "ss_01.inc"
    .align 256
                .include "ss_02.inc"
    .align 256
                .include "ss_13.inc"
    .align 256
                .include "ss_04.inc"
    .align 256
                .include "ss_05.inc"
    .align 256
                .include "flewww.inc"
    .align 256
                .include "ss_07.inc"
    .align 256
                .include "ss_08.inc"
    .align 256
                .include "ss_09.inc"
    .align 256
                .include "ss_10.inc" 
    .align 256
                .include "ss_11.inc" 
    .align 256
                .include "ss_12.inc" 
    .align 256
                .include "glafouk.inc"
