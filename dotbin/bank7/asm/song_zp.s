; =====================================================================
; Permanent variables. These are states needed by the player.
; =====================================================================

.export _tt_envelope_index_c0	; index into ADSR envelope
.export _tt_envelope_index_c1
.export _tt_cur_ins_c0		; current instrument
.export _tt_cur_ins_c1

;;; Expose volume on channels
.export _tt_cur_vol_c0		; Volume c0
.export _tt_cur_vol_c1		; Volume c1

.export _tt_song_ptr	     ; current music pointer
.export _tt_timer		; current music timer value
.export _tt_cur_pat_index_c0	; current pattern index into tt_SequenceTable
.export _tt_cur_pat_index_c1
.export _tt_cur_note_index_c0	; note index into current pattern
.export _tt_cur_note_index_c1


.zeropage
_tt_song_ptr:		.res 2    ; current music pointer
_tt_timer:		.res 1    ; current music timer value
_tt_cur_pat_index_c0:	.res 1    ; current pattern index into tt_SequenceTable
_tt_cur_pat_index_c1:	.res 1
_tt_cur_note_index_c0:	.res 1    ; note index into current pattern
_tt_cur_note_index_c1:	.res 1
_tt_envelope_index_c0:	.res 1    ; index into ADSR envelope
_tt_envelope_index_c1:	.res 1
_tt_cur_ins_c0:		.res 1    ; current instrument
_tt_cur_ins_c1:		.res 1
_tt_cur_vol_c0:		.res 1	  ; current volume
_tt_cur_vol_c1:		.res 1
