; =====================================================================
; Permanent variables. These are states needed by the player.
; =====================================================================

.importzp _tt_envelope_index_c0	; index into ADSR envelope
.importzp _tt_envelope_index_c1
.importzp _tt_cur_ins_c0	; current instrument
.importzp _tt_cur_ins_c1

;;; Expose volume on channels
.importzp _tt_cur_vol_c0	; Volume c0
.importzp _tt_cur_vol_c1	; Volume c1

.importzp _tt_song_ptr		; current music pointer
.importzp _tt_timer		; current music timer value
.importzp _tt_cur_pat_index_c0	; current pattern index into tt_SequenceTable
.importzp _tt_cur_pat_index_c1
.importzp _tt_cur_note_index_c0	; note index into current pattern
.importzp _tt_cur_note_index_c1
