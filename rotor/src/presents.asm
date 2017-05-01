;38 lignes!
;size byte:228bytes 

presents0:
        .byte $00,$c3,$e0,$67,$77,$77,$77,$73,$73,$73 
        .byte $73,$73,$73,$73,$73,$71,$70,$70,$70,$78 
        .byte $7c,$7f,$7f,$70,$70,$70,$70,$7f,$7f,$00 
        .byte $00,$00,$00,$00,$00,$00,$00,$00

presents1:
        .byte $00,$ff,$7f,$00,$8e,$8e,$9d,$b9,$f3,$e3 
        .byte $33,$1b,$0b,$9b,$fb,$f1,$00,$00,$00,$00 
        .byte $00,$80,$f0,$78,$18,$18,$38,$f0,$c0,$00 
        .byte $00,$00,$00,$00,$00,$00,$00,$00

presents2:
        .byte $00,$e0,$fe,$3f,$00,$ec,$f7,$f3,$91,$03 
        .byte $cf,$dc,$18,$9c,$ef,$e3,$00,$00,$0e,$0f 
        .byte $07,$03,$01,$00,$00,$00,$00,$00,$00,$00 
        .byte $00,$00,$00,$00,$00,$00,$00,$00

presents3:
        .byte $00,$03,$00,$fc,$ff,$01,$1c,$bd,$b5,$b1 
        .byte $3d,$3d,$31,$b9,$bd,$1d,$00,$00,$00,$00 
        .byte $80,$c0,$f0,$7e,$1f,$07,$01,$00,$00,$00 
        .byte $00,$00,$02,$20,$13,$87,$07,$00

presents4:
        .byte $00,$ff,$7f,$0f,$e3,$ff,$0f,$83,$9b,$bb 
        .byte $fb,$fb,$fb,$db,$9b,$9b,$03,$03,$03,$03 
        .byte $03,$03,$03,$03,$83,$f3,$ff,$7f,$0f,$03 
        .byte $03,$00,$20,$40,$00,$98,$80,$00

presents5:
        .byte $00,$ff,$f0,$c0,$00,$c0,$fc,$3e,$06,$0e 
        .byte $3c,$30,$63,$71,$7f,$3e,$00,$00,$00,$00 
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$c0,$f0 
        .byte $3c,$07,$00,$00,$00,$00,$00,$00

presents_tbl_lo:
        byte   <presents0, <presents1, <presents2 
        byte   <presents3, <presents4, <presents5 

presents_tbl_hi:
        byte   >presents0, >presents1, >presents2 
        byte   >presents3, >presents4, >presents5 

