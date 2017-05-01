;;; See: http://blog.kevtris.org/blogfiles/Atari%202600%20Mappers.txt
BANK0_SWITCH = $1FF4

; k65 communication
FXSetupReturn SUBROUTINE
        lda BANK0_SWITCH
        jmp MainLoop
FXKernelReturn SUBROUTINE
        lda BANK0_SWITCH
        jmp WaitForDisplayEnd
FXOverscanReturn SUBROUTINE
        lda BANK0_SWITCH
        jmp WaitForOverscanEnd
FXVBlankReturn SUBROUTINE
        lda BANK0_SWITCH
        jmp WaitForVBlankEnd


;FX_SWITCH = $1FF5               ; to $1FFB
;
;Start SUBROUTINE
;        lda BANK0_SWITCH        ; contains initialization code
;        jmp InitializeDemo
;
;FXNext:
;        inc demofxix
;        ldx demofxix
;        lda FX_SWITCH,X
;        lda demofxsetuphi,x
;        pha
;        lda demofxsetuplo,x
;        pha
;        rts
;
;; fx kernel functor table
;demofxlo:
;        .byte    #<(fx_picture_kernel-1)
;        .byte    #<(fx_rotozoom_kernel-1)
;        .byte    #<(fx_scrollv2_kernel-1)
;        .byte    #<(fx_rotozoom_kernel-1)
;        .byte    #<(fx_rotozoom_kernel-1)
;        .byte    #<(fx_rotozoom_kernel-1)
;        .byte    #<(fx_rotozoom_kernel-1)
;demofxhi:
;        .byte    #>(fx_picture_kernel-1)
;        .byte    #>(fx_rotozoom_kernel-1)
;        .byte    #>(fx_scrollv2_kernel-1)
;        .byte    #>(fx_rotozoom_kernel-1)
;        .byte    #>(fx_rotozoom_kernel-1)
;        .byte    #>(fx_rotozoom_kernel-1)
;        .byte    #>(fx_rotozoom_kernel-1)
;
;; fx setup functor table
;demofxsetuplo:
;        .byte    #<(fx_picture_setup-1)
;        .byte    #<(fx_rotozoom_setup-1)
;        .byte    #<(fx_scrollv2_setup-1)
;        .byte    #<(fx_rotozoom_setup-1)
;        .byte    #<(fx_rotozoom_setup-1)
;        .byte    #<(fx_rotozoom_setup-1)
;        .byte    #<(fx_rotozoom_setup-1)
;demofxsetuphi:
;        .byte    #>(fx_picture_setup-1)
;        .byte    #>(fx_rotozoom_setup-1)
;        .byte    #>(fx_scrollv2_setup-1)
;        .byte    #>(fx_rotozoom_setup-1)
;        .byte    #>(fx_rotozoom_setup-1)
;        .byte    #>(fx_rotozoom_setup-1)
;        .byte    #>(fx_rotozoom_setup-1)
;
;; =====================================================================
;; MAIN LOOP
;; =====================================================================
;
;MainLoop:
;
;; ---------------------------------------------------------------------
;; Overscan
;; ---------------------------------------------------------------------
;
;; wait for beam to finish overscan and start vsync
;WaitForOverscanEnd:
;        lda INTIM
;        bne WaitForOverscanEnd
;
;        inc time
;        bne VBlank
;        inc time+1
;
;; ---------------------------------------------------------------------
;; VBlank
;; ---------------------------------------------------------------------
;
;VBlank  SUBROUTINE
;        ; get new frame by setting VSYNC:D1 during 3 scanlines then disable it
;        lda #%1110
;.vsyncLoop:
;        sta WSYNC
;        sta VSYNC
;        lsr
;        bne .vsyncLoop
;        lda #%10
;        sta VBLANK      ; turn beam off (VBLANK:D1=1)
;        lda #TIM_VBLANK ; set vblank duration into timer
;        sta TIM64T
;
;        lda BANK0_SWITCH
;        jsr song_player
;
;        ldx demofxix
;        lda FX_SWITCH,X
;        ; call current fx, at beginning of VBlank
;        lda demofxhi,X
;        pha
;        lda demofxlo,X
;        pha
;        rts
;
;; wait for the current VBlank to end, after which visible scanlines start
;WaitForVBlankEnd:
;        lda INTIM
;        bne WaitForVBlankEnd
;        sta WSYNC
;        sta VBLANK      ; turn beam on (VBLANK:D1=0)
;        lda #TIM_KERNEL ; set horizontal draw duration into timer
;        sta T1024T
;        rts
;
;; wait for the end of visible scanlines and start of overscan
;WaitForDisplayEnd:
;        lda INTIM
;        bne WaitForDisplayEnd
;        sta WSYNC
;        lda #%10
;        sta VBLANK      ; turn beam off (VBLANK:D1=1)
;        lda #TIM_OVERSCAN ; set overscan duration into timer
;        sta TIM64T
;        rts
;
