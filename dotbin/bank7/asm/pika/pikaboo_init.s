.include "globals.inc"
.include "../banksetup.inc"
.include "../song_zp.inc"

.export _pika_tt_init

.segment CODE_SEGMENT

_pika_tt_init:
        lda #0
        sta _tt_cur_pat_index_c0
        lda #23
        sta _tt_cur_pat_index_c1

        lda #0
        sta _tt_timer
        sta _tt_cur_note_index_c0
        sta _tt_cur_note_index_c1

        jmp _bankReturn
