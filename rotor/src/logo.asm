;38 lignes!
;size byte:228bytes 

logo0:
        .byte $00,$64,$c8,$e3,$7e,$18,$01,$03,$07,$0f 
        .byte $0f,$1f,$1f,$3e,$3e,$3e,$7c,$7c,$fc,$ff 
        .byte $ff,$ff,$f8,$f8,$fc,$ff,$7f,$3f,$1f,$07 
        .byte $00,$00,$60,$00,$08,$30,$00,$00

logo1:
        .byte $00,$01,$fc,$87,$30,$f8,$e3,$cf,$df,$9f 
        .byte $be,$3c,$3c,$3c,$3c,$1c,$1c,$1e,$0e,$8e 
        .byte $ee,$e7,$f7,$33,$03,$01,$c0,$ff,$ff,$ff 
        .byte $7f,$00,$00,$00,$00,$08,$00,$00

logo2:
        .byte $00,$c4,$10,$87,$fc,$01,$c3,$e3,$f1,$f0 
        .byte $60,$0f,$7f,$ff,$f8,$f0,$e0,$e0,$70,$78 
        .byte $78,$3c,$1e,$8e,$86,$80,$00,$80,$f0,$f8 
        .byte $f0,$00,$00,$01,$06,$00,$00,$00

logo3:
        .byte $00,$02,$f1,$1c,$06,$e2,$f9,$fe,$ff,$ff 
        .byte $1f,$c7,$f3,$f9,$7c,$3e,$1e,$1e,$0e,$1e 
        .byte $3c,$7c,$79,$33,$07,$0f,$1e,$1f,$0f,$03 
        .byte $00,$00,$00,$80,$60,$00,$00,$00

logo4:
        .byte $00,$00,$83,$0e,$00,$03,$8e,$70,$01,$83 
        .byte $c3,$e3,$f3,$f3,$fb,$fb,$7b,$7b,$7b,$7b 
        .byte $f3,$f3,$e3,$c3,$83,$03,$03,$c3,$f0,$ff 
        .byte $7f,$03,$00,$00,$08,$00,$00,$00

logo5:
        .byte $00,$80,$06,$78,$c0,$86,$0e,$0e,$8e,$8e 
        .byte $8e,$8e,$8e,$8e,$9e,$fe,$fe,$fe,$fe,$ce 
        .byte $8e,$8e,$8e,$8e,$8e,$8e,$8e,$0c,$00,$c0 
        .byte $ff,$ff,$06,$03,$11,$30,$60,$00

logo_tbl_lo:
        byte   <logo0, <logo1, <logo2 
        byte   <logo3, <logo4, <logo5 

logo_tbl_hi:
        byte   >logo0, >logo1, >logo2 
        byte   >logo3, >logo4, >logo5 

