.include "globals.inc"
.include "banksetup.inc"

.importzp _fx_data
.export _fx_vrgirl

.segment CODE_SEGMENT

PATTERN_TIME_ZIK1 = 64*2
;FX_DURATION = PATTERN_TIME_ZIK1 * 12
FX_DURATION = 922
; pour que le glisse spectacle commence sur le snare (ceteris paribus) 922

; write over the C temporary variables ($8E can be used too if restored to 0)
counter = $8F

_fx_vrgirl:
    jsr _wait_overscan
    mDirectBankCall $4FFF    ; init

fx_vrgirl_kernel: ; for macro local labels
    lda #<FX_DURATION
    sta counter
    lda #>FX_DURATION
    sta counter+1
fx_vrgirl_loop:
    lda counter
    bne @lone
    lda counter+1
    beq fx_vrgirl_endl
    dec counter+1
@lone:
    dec counter
    jsr _wait_vblank
    mDirectBankCall $5002    ; kernel
    jsr _wait_overscan
fx_vrgirl_vblank:
    mDirectBankCall $5005    ; vblank
    jmp fx_vrgirl_loop
fx_vrgirl_endl:

    lda #0
    sta NUSIZ0
    sta NUSIZ1
    sta VDELP0
    sta VDELP1
    sta CTRLPF
    sta ENAM0
    sta ENAM1
    rts
