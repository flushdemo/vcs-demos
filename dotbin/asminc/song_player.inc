; Available music tracks (Init and Player methods)
; TIA Tracker Init and Player update subroutine
; .import _pika_tt_init
; .import _pika_tt_player

; .import _frisk_tt_init
; .import _frisk_tt_player

; .import _thund_tt_init
; .import _thund_tt_player

.import _forward_tt_init
.import _forward_tt_player

.import _salami_tt_init
.import _salami_tt_player

.import _koniec_tt_init
.import _koniec_tt_player

.importzp _tt_song_ptr

; Variables exposed by the Music framework
.importzp _tt_envelope_index_c0
.importzp _tt_envelope_index_c1
.importzp _tt_cur_ins_c0
.importzp _tt_cur_ins_c1
.importzp _tt_cur_vol_c0
.importzp _tt_cur_vol_c1

.importzp _tt_timer
.importzp _tt_cur_pat_index_c0
.importzp _tt_cur_pat_index_c1
.importzp _tt_cur_note_index_c0
.importzp _tt_cur_note_index_c1
