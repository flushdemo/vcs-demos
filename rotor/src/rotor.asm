;37 lignes!
;size byte:222bytes 

rotor0:
        .byte $ff,$ff,$ff,$ff,$18,$18,$18,$18,$18,$18 
        .byte $18,$18,$18,$01,$03,$01,$00,$00,$18,$18 
        .byte $18,$00,$01,$01,$03,$07,$ff,$ff,$ff,$e0 
        .byte $c0,$80,$80,$80,$80,$c0,$00

rotor1:
        .byte $ff,$ff,$ff,$ff,$e0,$c0,$80,$80,$86,$86 
        .byte $86,$86,$86,$86,$86,$86,$86,$86,$86,$86 
        .byte $86,$80,$80,$c0,$e0,$f0,$ff,$ff,$ff,$00 
        .byte $00,$00,$00,$00,$00,$00,$00

rotor2:
        .byte $ff,$fe,$fc,$fc,$7c,$3c,$1c,$1c,$1c,$1c 
        .byte $1c,$1c,$1c,$1c,$1c,$1c,$1c,$1c,$1c,$1c 
        .byte $3c,$3c,$3c,$3c,$7c,$fc,$f8,$f0,$e0,$00 
        .byte $00,$00,$00,$00,$00,$00,$00

rotor3:
        .byte $ff,$7f,$3f,$3f,$3e,$3c,$38,$38,$38,$38 
        .byte $38,$38,$38,$38,$38,$38,$38,$38,$38,$38 
        .byte $3c,$3c,$3c,$3c,$3e,$3f,$1f,$0f,$07,$00 
        .byte $00,$00,$00,$00,$00,$00,$00

rotor4:
        .byte $ff,$ff,$ff,$ff,$07,$03,$01,$01,$61,$61 
        .byte $61,$61,$61,$61,$61,$61,$61,$61,$61,$61 
        .byte $61,$01,$01,$01,$03,$07,$ff,$ff,$ff,$00 
        .byte $00,$00,$00,$00,$00,$00,$00

rotor5:
        .byte $ff,$ff,$ff,$ff,$18,$18,$18,$18,$18,$18 
        .byte $18,$18,$00,$80,$c0,$80,$00,$00,$18,$18 
        .byte $18,$00,$80,$80,$c0,$e0,$ff,$ff,$ff,$07 
        .byte $03,$01,$01,$01,$01,$03,$00

rotor_tbl_lo:
        byte   <rotor0, <rotor1, <rotor2 
        byte   <rotor3, <rotor4, <rotor5 

rotor_tbl_hi:
        byte   >rotor0, >rotor1, >rotor2 
        byte   >rotor3, >rotor4, >rotor5 

