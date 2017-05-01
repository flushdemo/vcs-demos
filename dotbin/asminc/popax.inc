.macro popax
        ldy     #1
        lda     (sp),y          ; get hi byte
        tax                     ; into x
        dey
        lda     (sp),y          ; get lo byte
        inc     sp              ; 5
        inc     sp              ; 5
.endmacro
