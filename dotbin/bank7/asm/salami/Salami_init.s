.include "globals.inc"
.include "../banksetup.inc"
.include "../song_zp.inc"

.import _salami_tt_player
.export _salami_tt_init

.segment CODE_SEGMENT

_salami_tt_init:
        lda #>_salami_tt_player
        sta _tt_song_ptr
        lda #<_salami_tt_player
        sta _tt_song_ptr+1

        lda #0
        sta _tt_cur_pat_index_c0
        lda #30
        sta _tt_cur_pat_index_c1

        lda #0
        sta _tt_timer
        sta _tt_cur_note_index_c0
        sta _tt_cur_note_index_c1

        jmp _bankReturn
