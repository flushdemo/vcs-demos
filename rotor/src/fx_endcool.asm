;posa     = fxdata 
;rd       = fxdata + 2
;seed     = fxdata + 6
;fade     = fxdata + 8
;compt    = fxdata + 10
;tempo    = fxdata + 12
;fxtime   = fxdata + 18
;fxtimend = fxdata + 32

fx_endcool_setup SUBROUTINE
                lda #0
                sta compt
                sta fade
                sta VDELP0
                sta VDELP1 
                lda #$90
                sta seed
                lda #0
                sta GRP0
                sta GRP1
                
                lda #$00        
                sta CTRLPF
                lda #$0
                sta posa
                lda #$2 ; $6C
                sta COLUP0
                lda #$2 ; $6E
                sta COLUP1
                LDA #$FA
                STA HMP1
                STA HMOVE
                LDA #$0
                STA HMP0
                lda #$0  ;$0E     
                sta PF2                 ; 3                
                Sta PF1
                sta PF0
                lda #$07 ;$04      
                sta COLUPF
                lda #$0
                sta COLUBK
                lda #5
                sta NUSIZ0
                sta NUSIZ1
               
                ;jmp MainLoop
                rts
                
fx_endcool_showplayfield:
                ldx rd
                lda fx_endcool_rantab,X
                inc rd
                sta PF2               
                lda fx_endcool_rantab,X+2
                inc rd
                Sta PF1
                lda fx_endcool_rantab,X+3
                sta PF0
                rts
                
fx_endcool_changecol:
                inc compt
                ldy compt
                cpy $2F
                bmi .skip
                
                ldy #0
                sty compt

                ldy fade
                lda fx_endcool_fade,Y
                sta COLUP0
                sta COLUP1

                iny 
                cpy #16
                bmi .nah
                ldy #0
.nah            
                sty fade
.skip   
                rts

fx_endcool_kernel SUBROUTINE
                ;jsr WaitForVBlankEnd
                ldy #0
                sta WSYNC
fx_endcool_domorepf:                
                jsr fx_endcool_showplayfield
                sta WSYNC
                sta WSYNC
                iny
                cpy #8
                bne fx_endcool_domorepf

                jsr fx_endcool_changecol                
                
                ldy #0
                
                

fx_endcool_midfirst
                sta seed
                sta WSYNC  
                inc rd
                
                REPEAT 17
                nop
                REPEND
                sta RESP0    
                nop
                
                sta RESP1
                STY tempo_endcool
                ldy posa
           
                ldx fx_endcool_e,Y+1
                stx GRP0                
                ldx fx_endcool_e,Y
                stx GRP1
                sta WSYNC

                jsr fx_endcool_showplayfield
                inc posa
                inc posa
               
                ldy tempo_endcool
                iny
                cpy #30
                bne fx_endcool_midfirst
                
                jsr fx_endcool_changecol                
                ldy #0
                sty posa

fx_endcool_midcenter:
                sta seed
                sta WSYNC  
                inc rd
                
                REPEAT 17
                nop
                REPEND
                sta RESP0    
                nop
                
                sta RESP1
                STY tempo_endcool
                ldy posa
           
                ldx fx_endcool_n,Y+1
                stx GRP0                
                ldx fx_endcool_n,Y
                stx GRP1
                sta WSYNC

                jsr fx_endcool_showplayfield
                inc posa
                inc posa
               
                ldy tempo_endcool
                iny
                cpy #30
                bne fx_endcool_midcenter

                jsr fx_endcool_changecol
                ldy #0
                sty posa

fx_endcool_midfin:
                sta seed
                sta WSYNC  
                inc rd
                
                REPEAT 17
                nop
                REPEND
                sta RESP0    
                nop
                
                sta RESP1
                STY tempo_endcool
                ldy posa
           
                ldx fx_endcool_d,Y+1
                stx GRP0                
                ldx fx_endcool_d,Y
                stx GRP1
                sta WSYNC

                jsr fx_endcool_showplayfield
                inc posa
                inc posa
               
                ldy tempo_endcool
                iny
                cpy #20
                bne fx_endcool_midfin
            
                jsr fx_endcool_changecol                
                ldy #0
fx_endcool_morepf:
                jsr fx_endcool_showplayfield
                sta WSYNC
                sta WSYNC
                
                iny
                cpy #8
                bne fx_endcool_morepf
                
                lda #$0
                tax 
                stx GRP0
                stx GRP1
                stx PF1
                stx PF2
                stx PF0
                lda #0
                sta posa
                
                inc fxtime_endcool
                lda fxtime_endcool
                cmp #$FF
                beq .mefin
                ;jsr WaitForDisplayEnd
                ;jmp MainLoop
                rts
.mefin
                inc fxtimend_endcool
                lda fxtimend_endcool
                cmp #$9
                beq .thefin
                ;jsr WaitForDisplayEnd
                ;jmp MainLoop
                rts
.thefin                
                ;jsr WaitForDisplayEnd
                ;jmp FXNext    
                rts
                .align 256
                
fx_endcool_e:

        byte    $ff,$ff,$ff,$ff,$ff,$ff,$00,$e0,$00,$e0,$00,$e0
        byte    $00,$e0,$00,$e0,$e0,$ff,$e0,$ff,$e0,$ff,$00,$e0
        byte    $00,$e0,$00,$e0,$00,$e0,$00,$e0,$ff,$ff,$ff,$ff
        byte    $ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

       
fx_endcool_n:

        byte    $07,$f0,$07,$f8,$07,$f8,$07,$fc,$07,$fe,$07,$ee
        byte    $07,$e7,$87,$e7,$87,$e3,$c7,$e3,$c7,$e1,$e7,$e0
        byte    $f7,$e0,$77,$e0,$3f,$e0,$3f,$e0,$1f,$e0,$1f,$e0
        byte    $0f,$e0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

fx_endcool_d:

        byte    $f0,$ff,$fc,$ff,$fe,$ff,$0e,$e0,$07,$e0,$07,$e0
        byte    $07,$e0,$07,$e0,$07,$e0,$07,$e0,$07,$e0,$07,$e0
        byte    $07,$e0,$07,$e0,$07,$e0,$0e,$e0,$fe,$ff,$fc,$ff
        byte    $f8,$ff,$00,$00
        
fx_endcool_fade:

         byte   $02,$04,$06,$08,$0A,$0C,$0E,$0E
         byte   $0E,$0E,$0C,$0A,$08,$06,$04,$02
          
fx_endcool_rantab:
        byte    $17,$71,$9b,$6b,$de,$91,$f9,$9d,$c7,$99,$72,$6f,$8c,$cb,$29,$61
        byte    $4e,$34,$7e,$57,$24,$8d,$29,$40,$de,$8f,$fe,$03,$6d,$63,$05,$f8
        byte    $99,$6b,$9f,$05,$e7,$a4,$9a,$90,$ca,$33,$89,$a3,$61,$e9,$38,$7b
        byte    $9a,$73,$7b,$a5,$0a,$60,$2a,$12,$49,$91,$3f,$71,$8c,$51,$8b,$b9
        byte    $3c,$08,$a5,$ee,$20,$bf,$b1,$20,$3a,$f8,$ff,$8f,$ac,$3a,$d9,$b4
        byte    $5b,$04,$56,$b5,$af,$cb,$6b,$fe,$ee,$86,$79,$74,$dc,$ea,$fe,$90
        byte    $8f,$68,$bf,$b2,$66,$fc,$d2,$18,$42,$05,$71,$b7,$98,$c1,$8c,$b1
        byte    $b0,$c5,$fc,$e1,$e2,$67,$69,$46,$62,$1f,$e2,$a2,$d6,$a9,$e3,$7d
        byte    $b2,$9d,$9a,$77,$ad,$1a,$cc,$97,$57,$c3,$b7,$66,$5e,$cf,$47,$44
        byte    $51,$db,$36,$ce,$87,$39,$aa,$de,$98,$4b,$21,$48,$50,$68,$c8,$dd
        byte    $d7,$74,$50,$c5,$59,$fd,$f8,$2d,$98,$27,$07,$6b,$1d,$63,$45,$4a
        byte    $c6,$f5,$8a,$ab,$c9,$a3,$25,$b9,$8a,$52,$9a,$ca,$30,$ad,$17,$81
        byte    $0b,$b1,$58,$a7,$9e,$6d,$3f,$0b,$da,$4d,$bd,$cf,$0a,$4d,$67,$c9
        byte    $3d,$ab,$e3,$1b,$65,$c8,$eb,$4c,$80,$c1,$3d,$3e,$49,$48,$60,$d8
        byte    $0b,$d3,$ff,$b8,$ba,$08,$0c,$ca,$73,$d9,$5e,$ce,$ca,$f8,$c5,$b3
        byte    $95,$ac,$3b,$2d,$b9,$84,$b1,$8f,$33,$1f,$40,$31,$2e,$69,$59
    
