        processor 6502
        include "vcs.h"

; TV format switches
PAL             = 0
NTSC            = 1

; HBlank:  68
; HDraw : 160
;         228
        IF PAL
; <338 scanlines>
; [  3]  VSYNC
; [ 40]  VBLANK
; [256] HB HDRAW
; [ 36]  OVERSCAN
TIM_VBLANK      = 43
TIM_OVERSCAN    = 36
TIM_KERNEL      = 19 ; 256
DISP_SCANLINES  = 242
        ELSE
; <288 scanlines>
; [  3]  VSYNC
; [ 42]  VBLANK
; [202] HB HDRAW
; [ 38]  OVERSCAN
TIM_VBLANK      = 45
TIM_OVERSCAN    = 38
TIM_KERNEL      = 15 ; 202
DISP_SCANLINES  = 192
        ENDIF

; =====================================================================
; Variables
; =====================================================================

        SEG.U   variables
        ORG     $E0

        include "song_variables.asm"

; index of current fx
demofxix    ds 1                ; $8b
; frame counter
time        ds 1                ; $8c
; fx ram start
fxdata      ds 1                ; $8d

        ORG     $80
        include "fx_picture_variables.asm"
        include "fx_endcool_variables.asm"
        include "fx_rotozoom_variables.asm"
        include "fx_scrollv2_variables.asm"
        include "fx_tunnel_variables.asm"


; =====================================================================
; Start of code
; =====================================================================

;;; Start Bank0
        SEG     Bank0
        ORG     $8000
        RORG    $F000
        include "common_code.asm"

        echo "Common code end: ", *


InitializeDemo SUBROUTINE

        ; Clear zeropage
        cld
        ldx #0
        txa
.clearLoop:
        dex
        txs
        pha
        bne .clearLoop

        include "song_init.asm"

        jmp FXSetup
MainLoop:
        sta WSYNC
        lda #2
        sta VBLANK
        lda #TIM_OVERSCAN
        sta TIM64T

        jsr song_player

        inc time
        jmp FXOverscan
WaitForOverscanEnd:
        lda INTIM
        bne WaitForOverscanEnd

.VBlank
        ; get new frame by setting VSYNC:D1 during 3 scanlines then disable it
        lda #%1110
.vsyncLoop:
        sta WSYNC
        sta VSYNC
        lsr
        bne .vsyncLoop
        lda #%10
        sta VBLANK      ; turn beam off (VBLANK:D1=1)
        lda #TIM_VBLANK ; set vblank duration into timer
        sta TIM64T
        jmp FXVBlank
; wait for the current VBlank to end, after which visible scanlines start
WaitForVBlankEnd:
        lda INTIM
        bne WaitForVBlankEnd
        sta WSYNC
        sta VBLANK      ; turn beam on (VBLANK:D1=0)

        lda #TIM_KERNEL ; set horizontal draw duration into timer
        sta T1024T
        jmp FXKernel
; wait for the end of visible scanlines and start of overscan
WaitForDisplayEnd:
        lda INTIM
        bne WaitForDisplayEnd
        sta WSYNC
        lda #%10
        sta VBLANK      ; turn beam off (VBLANK:D1=1)
        lda #TIM_OVERSCAN ; set overscan duration into timer
        sta TIM64T

        jmp MainLoop


;;; ===================================================================
;;; Music
;;; ===================================================================

song_player
        include "song_player.asm"
        rts
        include "song_trackdata.asm"

; Change the [R]ORG to match your test FX here 
        ORG     $8f0d
        RORG    $ff0d
FXSetup:
        lda     BANK0_SWITCH+1
        lda     BANK0_SWITCH
        ORG     $8f13
        RORG    $ff13
FXKernel:
        lda     BANK0_SWITCH+1
        lda     BANK0_SWITCH
        ORG     $8f19
        RORG    $ff19
FXOverscan:
        jmp     WaitForOverscanEnd ; no func
        ;lda     BANK0_SWITCH+1
        lda     BANK0_SWITCH
        ORG     $8f1f
        RORG    $ff1f
FXVBlank:
        jmp     WaitForVBlankEnd ; no func
        ;lda     BANK0_SWITCH+1
        lda     BANK0_SWITCH
        
        ORG     $8fe3
        RORG    $ffe3
        jmp     InitializeDemo
        jmp     InitializeDemo
        ORG     $8ffc
        RORG    $fffc
        .word   $ffe3
        .word   $ffe3
;;; End Bank0

;;; ===================================================================
;;; FXs
;;; ===================================================================

;;; Start Bank1
        SEG     Bank1
        ORG     $9000
        RORG    $f000
        include "common_code.asm"
        include "fx_picture.asm"
        include "fx_endcool.asm"
        ORG     $9f04
        RORG    $ff04
        jsr     fx_endcool_setup
        jmp     FXSetupReturn
        jsr     fx_endcool_kernel
        jmp     FXKernelReturn
        jsr     fx_picture_setup
        jmp     FXSetupReturn
        jsr     fx_picture_kernel
        jmp     FXKernelReturn
        ORG     $9fe3
        RORG    $ffe3
        lda     BANK0_SWITCH
        ORG     $9ffc
        RORG    $fffc
        .word   $ffe3
        .word   $ffe3
;;; End Bank1

;;; Start Bank2
        SEG     Bank2
        ORG     $a000
        RORG    $f000
        include "common_code.asm"
        include "fx_rotozoom.asm"
        ORG     $af20
        RORG    $ff20
        jsr     fx_rotozoom_setup
        jmp     FXSetupReturn
        jsr     fx_rotozoom_kernel
        jmp     FXKernelReturn
        jsr     fx_rotozoom_overscan
        jmp     FXOverscanReturn
        jsr     fx_rotozoom_vblank
        jmp     FXVBlankReturn
        ORG     $afe3
        RORG    $ffe3
        lda     BANK0_SWITCH
        ORG     $affc
        RORG    $fffc
        .word   $ffe3
        .word   $ffe3
;;; End Bank2

;;; Start Bank3
        SEG     Bank3
        ORG     $b000
        RORG    $f000
        include "common_code.asm"
        include "fx_scrollv2.asm"
        ORG     $bf40
        RORG    $ff40
        jsr     fx_scrollv2_setup
        jmp     FXSetupReturn
        jsr     fx_scrollv2_kernel
        jmp     FXKernelReturn
        jsr     fx_scrollv2_overscan
        jmp     FXOverscanReturn
        jsr     fx_scrollv2_vblank
        jmp     FXVBlankReturn
        ORG     $bfe3
        RORG    $ffe3
        lda     BANK0_SWITCH
        ORG     $bffc
        RORG    $fffc
        .word   $ffe3
        .word   $ffe3
;;; End Bank3

;;; Start Bank4
        SEG     Bank4
        ORG     $c000
        RORG    $f000
        include "common_code.asm"
        include "fx_tunnel.asm"
        include "rotor.asm"
        ORG     $cf60
        RORG    $ff60
        jsr     fx_tunnel_setup
        jmp     FXSetupReturn
        jsr     fx_tunnel_kernel
        jmp     FXKernelReturn
        jsr     fx_tunnel_overscan
        jmp     FXOverscanReturn
        jsr     fx_tunnel_vblank
        jmp     FXVBlankReturn
        ORG     $cfe3
        RORG    $ffe3
        lda     BANK0_SWITCH
        ORG     $cffc
        RORG    $fffc
        .word   $ffe3
        .word   $ffe3
;;; End Bank4

;;; Start Bank5
        SEG     Bank5
        ORG     $d000
        RORG    $f000
        include "common_code.asm"
        include "fx_rotozoom.asm"
        ORG     $dfe3
        RORG    $ffe3
        lda     BANK0_SWITCH
        ORG     $dffc
        RORG    $fffc
        .word   $ffe3
        .word   $ffe3
;;; End Bank5

;;; Start Bank6
        SEG     Bank6
        ORG     $e000
        RORG    $f000
        include "common_code.asm"
        include "fx_rotozoom.asm"
        ORG     $efe3
        RORG    $ffe3
        lda     BANK0_SWITCH
        ORG     $effc
        RORG    $fffc
        .word   $ffe3
        .word   $ffe3
;;; End Bank6

;;; Start Bank7
        SEG     Bank7
        ORG     $f000
        include "common_code.asm"
        include "fx_rotozoom.asm"
        ORG     $ffe3
        lda     BANK0_SWITCH
        ORG     $fffc
        .word   $ffe3
        .word   $ffe3
;;; End Bank7

; =====================================================================
; Vectors
; =====================================================================

        ;echo "ROM left: ", ($fffc - *)
