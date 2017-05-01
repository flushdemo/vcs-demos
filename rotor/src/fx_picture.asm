HEIGHT  EQU     #38

  MAC SLEEP
    IF {1} = 1
      ECHO "ERROR: SLEEP 1 not allowed !"
      END
    ENDIF
    IF {1} & 1
      nop $00
      REPEAT ({1}-3)/2
        nop
      REPEND
    ELSE
      REPEAT ({1})/2
        nop
      REPEND
    ENDIF
  ENDM


            
            
                .align 256

fx_picture_setup SUBROUTINE
                
                lda #0
                sta posy
                sta fxtimebc
                
                ldx #0
                lda logo_tbl_lo,x
                sta ptr
                adc HEIGHT
                sta ptr+2
                adc HEIGHT
                sta ptr+4

                lda logo_tbl_lo+3,x
                sta ptr+6
                adc HEIGHT
                sta ptr+8
                adc HEIGHT
                sta ptr+10

                lda logo_tbl_hi,x
                sta ptr+1
                sta ptr+3
                sta ptr+5
                lda logo_tbl_hi+3,x
                sta ptr+7
                sta ptr+9
                sta ptr+11
                
                lda #$0
                lda #$9E
                sta COLUP0
                lda #$9E
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
                ;jmp MainLoop
                rts

fx_picture_kernel:
                ;jsr WaitForVBlankEnd
                ldy #20
                
.bordnoirfix         
                sta WSYNC
                dey
                bne .bordnoirfix
                sta WSYNC
                lda #%11111111          ; 2

                sta PF2                 ; 3                
                Sta PF1
                sta PF0
                sta WSYNC
                ldx posy
                ldy sintbl,X
                
.picVbl         
                sta WSYNC
                dey
                bne .picVbl                  
                ldy #40
.picVblfix         

                sta WSYNC
                dey
                bne .picVblfix
                SLEEP   53
                lda     #%00000000          
                ldy     #HEIGHT           
                
                
.picmid   
                sty tempp       ;3   
                lda (ptr+$0),y  ;5        
                sta GRP0        ;3
                lda (ptr+$2),y  ;5       
                sta GRP1        ;3  

                sty COLUP0
                sty COLUP1
                nop
                
                lda (ptr+$4),y  ;5        
                sta GRP0        ;3        
                
                lda (ptr+$6),y  ;5        
                sta tempo       ;3     

                lax (ptr+$a),y  ;5        
                lda (ptr+$8),y  ;5        
                ldy tempo       ;3      
                sty GRP1        ;3        
                sta GRP0        ;3        
                stx GRP1        ;3        
                sta GRP0        ;3        
                ldy tempp       ;3
                dey             ;2
                bne .picmid     ;2
                lda #0
                SLEEP 13
                
                lda #$0
                sta GRP0
                sta GRP1
                
                ldy #54 ;84
                
.finraster         

                sta WSYNC
                dey
                bne .finraster
                
                lda #$0
                sta COLUPF
          
                
                ldx posy
                cpx #78
                bmi .incposy
                lda #0
                sta posy
.incposy
                inc posy
                inc fxtime
                lda fxtime
                cmp #$C0    ;<<<<<<< ça et le truc en dessous à modifier pour rallonger la durée de "flush"
                beq .resetfxtime

                rts
                
.resetfxtime                
                inc fxtimebc
                lda fxtimebc
                cmp #$02    ; <<<<<<< et çaaaaaaaaaaaaa !
                bpl .mefin

                lda #$0
                sta fxtime
                ;jsr WaitForDisplayEnd
                ;jmp MainLoop
                rts

.mefin
                inc fxtimend
                lda fxtimend
                cmp #$2                ;$5
                beq .thefin

                ;cmp #$1
                ;bmi .skipresent
                ; Remplace le logo flush par "presents"
                ldx #0
                lda presents_tbl_lo,x
                sta ptr
                adc HEIGHT
                sta ptr+2
                adc HEIGHT
                sta ptr+4

                lda presents_tbl_lo+3,x
                sta ptr+6
                adc HEIGHT
                sta ptr+8
                adc HEIGHT
                sta ptr+10

                lda presents_tbl_hi,x
                sta ptr+1
                sta ptr+3
                sta ptr+5
                lda presents_tbl_hi+3,x
                sta ptr+7
                sta ptr+9
                sta ptr+11
.skipresent               
               
                ;jsr WaitForDisplayEnd
                ;jmp MainLoop
                rts
            
.thefin                
                ;jmp FXNext    
                rts


                
                .align 256
                include "logo.asm"
                .align 256
                include "presents.asm"
        
                .align 256

sintbl: ; 64 entries

    .byte 9, 9, 9, 9, 9, 9, 9
    .byte 10, 10, 10, 10, 10, 10, 10
    .byte 12, 12, 12, 12, 12, 12, 12
    .byte 16, 16, 16, 16, 16, 16
    .byte 22, 22, 22, 22, 22
    .byte 26, 26, 26, 26
    .byte 30, 30, 30
    .byte 32
    .byte 32
    .byte 32
    .byte 32
    .byte 32
    .byte 32
    .byte 32
    .byte 32
    .byte 32
    .byte 32
    .byte 30, 30, 30
    .byte 26, 26, 26, 26
    .byte 22, 22, 22, 22, 22
    .byte 16, 16, 16, 16, 16, 16
    .byte 12, 12, 12, 12, 12, 12, 12
    .byte 10, 10, 10, 10, 10, 10, 10
    .byte 9, 9, 9, 9, 9, 9, 9
