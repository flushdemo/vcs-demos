.include "../banksetup.inc"

.export thund_tt_TrackDataStart
.export thund_tt_InsCtrlTable
.export thund_tt_InsADIndexes
.export thund_tt_InsSustainIndexes
.export thund_tt_InsReleaseIndexes
.export thund_tt_InsFreqVolTable
.export thund_tt_PercIndexes
.export thund_tt_PercFreqTable
.export thund_tt_PercCtrlVolTable
.export thund_tt_PatternPtrHi
.export thund_tt_PatternPtrLo
.export thund_tt_SequenceTable

.segment RODATA_SEGMENT

thund_tt_TrackDataStart:

thund_tt_InsCtrlTable:
        .byte $06, $08, $01, $07, $01


; Instrument Attack/Decay start indexes into ADSR tables.
thund_tt_InsADIndexes:
        .byte $00, $12, $20, $62, $6c


; Instrument Sustain start indexes into ADSR tables
thund_tt_InsSustainIndexes:
        .byte $0e, $1c, $5e, $68, $6c


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
thund_tt_InsReleaseIndexes:
        .byte $0f, $1d, $5f, $69, $6d


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
thund_tt_InsFreqVolTable:
; 0: gabbaKick
        .byte $7f, $0f, $0f, $1e, $4d, $5c, $6a, $78
        .byte $87, $95, $a4, $b3, $c2, $d1, $e0, $00
        .byte $f0, $00
; 1: hatnoise
        .byte $8f, $8c, $89, $87, $86, $85, $84, $93
        .byte $f2, $f1, $f0, $00, $f0, $00
; 2: SlowDown
        .byte $0f, $0f, $1f, $1f, $2f, $2f, $3f, $3f
        .byte $4f, $4f, $5f, $5f, $6f, $6f, $7f, $7f
        .byte $8f, $8f, $9f, $9f, $af, $af, $bf, $bf
        .byte $cf, $cf, $df, $df, $ef, $ef, $ff, $ff
        .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
        .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
        .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
        .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00
        .byte $f0, $00
; 3: bassline
        .byte $8d, $8d, $8d, $8d, $8d, $9d, $80, $00
        .byte $80, $00
; 4: SlowDownLoop
        .byte $8f, $00, $8f, $8f, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - thund_tt_PercIndexes: The index of the first percussion frame as defined
;       in thund_tt_PercFreqTable and thund_tt_PercCtrlVolTable
; - thund_tt_PercFreqTable: The AUDF frequency value
; - thund_tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in thund_tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
thund_tt_PercIndexes:
        .byte $01


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; THUND_TT_USE_OVERLAY)
thund_tt_PercFreqTable:
; 0: Clap
        .byte $07, $08, $09, $0a, $0b, $0c, $0e, $10
        .byte $12, $15, $18, $1b, $1e, $1f, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
thund_tt_PercCtrlVolTable:
; 0: Clap
        .byte $8d, $8c, $8b, $8a, $89, $88, $87, $86
        .byte $85, $84, $83, $82, $81, $80, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - thund_tt_PatternX (X=0, 1, ...): Pattern definitions
; - thund_tt_PatternPtrLo/Hi: Pointers to the thund_tt_PatternX tables, serving
;       as index values
; - thund_tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into thund_tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       _tt_cur_pat_index_c0/1 hold an index into thund_tt_SequenceTable for
;       each channel.
;
; So thund_tt_SequenceTable holds indexes into thund_tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (thund_tt_PatternX) in which the notes
; to play are specified.
; =====================================================================

; ---------------------------------------------------------------------
; Pattern definitions, one table per pattern. _tt_cur_note_index_c0/1
; hold the index values into these tables for the current pattern
; played in channel 0 and 1.
;
; A pattern is a sequence of notes (one byte per note) ending with a 0.
; A note can be either:
; - Pause: Put melodic instrument into release. Must only follow a
;       melodic instrument.
; - Hold: Continue to play last note (or silence). Default "empty" note.
; - Slide (needs THUND_TT_USE_SLIDE): Adjust frequency of last melodic note
;       by -7..+7 and keep playing it
; - Play new note with melodic instrument
; - Play new note with percussion instrument
; - End of pattern
;
; A note is defined by:
; - Bits 7..5: 1-7 means play melodic instrument 1-7 with a new note
;       and frequency in bits 4..0. If bits 7..5 are 0, bits 4..0 are
;       defined as:
;       - 0: End of pattern
;       - [1..15]: Slide -7..+7 (needs THUND_TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------

; bd0
thund_tt_pattern0:
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $08, $08
        .byte $00

; bd1
thund_tt_pattern1:
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $34, $08
        .byte $00

; bd2
thund_tt_pattern2:
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $08, $08
        .byte $34, $08, $34, $08, $34, $08, $34, $08
        .byte $34, $08, $08, $08, $34, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $34, $08
        .byte $34, $08, $08, $08, $34, $08, $34, $08
        .byte $00

; bd+hit0
thund_tt_pattern3:
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $08, $08
        .byte $00

; bd+hit1
thund_tt_pattern4:
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $34, $08
        .byte $00

; bd+hit2
thund_tt_pattern5:
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $34, $08, $34, $08, $34, $08
        .byte $34, $08, $08, $08, $34, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $34, $08
        .byte $34, $08, $08, $08, $34, $08, $34, $08
        .byte $00

; Blank
thund_tt_pattern6:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $00

; hit3
thund_tt_pattern7:
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $00

; hit+bd-up0
thund_tt_pattern8:
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $34, $08, $08, $08, $40, $08, $08, $08
        .byte $00

; break1.2
thund_tt_pattern9:
        .byte $77, $08, $08, $08, $40, $08, $08, $08
        .byte $7f, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $00

; hit0
thund_tt_pattern10:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $00

; hit1
thund_tt_pattern11:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $00

; hit2
thund_tt_pattern12:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $00

; hit+clap0
thund_tt_pattern13:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $40, $08, $08, $08
        .byte $00

; hit+clap1
thund_tt_pattern14:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $11, $08, $08, $08, $11, $08, $08, $08
        .byte $00

; hit+clap2
thund_tt_pattern15:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $11, $08, $08, $08, $40, $08, $08, $08
        .byte $08, $08, $08, $08, $40, $08, $08, $08
        .byte $11, $08, $08, $08, $11, $08, $08, $08
        .byte $00

; bass+clap0
thund_tt_pattern16:
        .byte $91, $08, $08, $08, $91, $08, $08, $08
        .byte $11, $08, $08, $08, $91, $08, $08, $08
        .byte $91, $08, $08, $08, $91, $08, $08, $08
        .byte $11, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $11, $08, $08, $08, $91, $08, $08, $08
        .byte $8e, $08, $08, $08, $11, $08, $8e, $08
        .byte $11, $08, $08, $08, $8e, $08, $08, $08
        .byte $00

; bass+clap1
thund_tt_pattern17:
        .byte $91, $08, $08, $08, $91, $08, $08, $08
        .byte $11, $08, $08, $08, $91, $08, $08, $08
        .byte $91, $08, $08, $08, $91, $08, $08, $08
        .byte $11, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $11, $08, $08, $08, $91, $08, $08, $08
        .byte $92, $08, $08, $08, $11, $08, $92, $08
        .byte $11, $08, $08, $08, $92, $08, $08, $08
        .byte $00

; bass+clap2
thund_tt_pattern18:
        .byte $8c, $08, $08, $08, $8c, $08, $08, $08
        .byte $11, $08, $08, $08, $8c, $08, $08, $08
        .byte $8c, $08, $08, $08, $8c, $08, $08, $08
        .byte $11, $08, $08, $08, $8c, $08, $08, $08
        .byte $08, $08, $08, $08, $8c, $08, $08, $08
        .byte $11, $08, $08, $08, $8c, $08, $08, $08
        .byte $8e, $08, $08, $08, $11, $08, $8e, $08
        .byte $11, $08, $08, $08, $8e, $08, $08, $6b
        .byte $00

; bass0
thund_tt_pattern19:
        .byte $91, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $91, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $8e, $08, $08, $08, $08, $08, $8e, $08
        .byte $08, $08, $08, $08, $8e, $08, $08, $08
        .byte $00

; bass1
thund_tt_pattern20:
        .byte $91, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $91, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $08, $08, $08, $08, $91, $08, $08, $08
        .byte $92, $08, $08, $08, $08, $08, $92, $08
        .byte $08, $08, $08, $08, $92, $08, $08, $08
        .byte $00

; bass2
thund_tt_pattern21:
        .byte $8c, $08, $08, $08, $8c, $08, $08, $08
        .byte $08, $08, $08, $08, $8c, $08, $08, $08
        .byte $8c, $08, $08, $08, $8c, $08, $08, $08
        .byte $08, $08, $08, $08, $8c, $08, $08, $08
        .byte $08, $08, $08, $08, $8c, $08, $08, $08
        .byte $08, $08, $08, $08, $8c, $08, $08, $08
        .byte $8e, $08, $08, $08, $08, $08, $8e, $08
        .byte $08, $08, $08, $08, $8e, $08, $08, $08
        .byte $00

; break1
thund_tt_pattern22:
        .byte $6b, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $b2, $08, $10, $08, $b2, $08, $10, $08
        .byte $b2, $08, $10, $08, $b2, $08, $10, $08
        .byte $b2, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $00

; break1.3
thund_tt_pattern23:
        .byte $6b, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $b1, $08, $10, $08, $b0, $08, $10, $08
        .byte $af, $08, $10, $08, $ae, $08, $10, $08
        .byte $ad, $08, $08, $08, $08, $08, $08, $08
        .byte $aa, $08, $08, $08, $ad, $08, $08, $10
        .byte $00


; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
thund_tt_PatternPtrLo:
        .byte <thund_tt_pattern0, <thund_tt_pattern1, <thund_tt_pattern2, <thund_tt_pattern3
        .byte <thund_tt_pattern4, <thund_tt_pattern5, <thund_tt_pattern6, <thund_tt_pattern7
        .byte <thund_tt_pattern8, <thund_tt_pattern9, <thund_tt_pattern10, <thund_tt_pattern11
        .byte <thund_tt_pattern12, <thund_tt_pattern13, <thund_tt_pattern14, <thund_tt_pattern15
        .byte <thund_tt_pattern16, <thund_tt_pattern17, <thund_tt_pattern18, <thund_tt_pattern19
        .byte <thund_tt_pattern20, <thund_tt_pattern21, <thund_tt_pattern22, <thund_tt_pattern23

thund_tt_PatternPtrHi:
        .byte >thund_tt_pattern0, >thund_tt_pattern1, >thund_tt_pattern2, >thund_tt_pattern3
        .byte >thund_tt_pattern4, >thund_tt_pattern5, >thund_tt_pattern6, >thund_tt_pattern7
        .byte >thund_tt_pattern8, >thund_tt_pattern9, >thund_tt_pattern10, >thund_tt_pattern11
        .byte >thund_tt_pattern12, >thund_tt_pattern13, >thund_tt_pattern14, >thund_tt_pattern15
        .byte >thund_tt_pattern16, >thund_tt_pattern17, >thund_tt_pattern18, >thund_tt_pattern19
        .byte >thund_tt_pattern20, >thund_tt_pattern21, >thund_tt_pattern22, >thund_tt_pattern23
        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; thund_tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. _tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If THUND_TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
thund_tt_SequenceTable:
        ; ---------- Channel 0 ----------
        .byte $00, $01, $00, $02, $03, $04, $03, $05
        .byte $03, $04, $03, $05, $03, $04, $03, $05
        .byte $03, $04, $03, $05, $06, $06, $07, $08
        .byte $03, $04, $03, $05, $09, $09, $03, $04
        .byte $84

        
        ; ---------- Channel 1 ----------
        .byte $06, $06, $06, $06, $0a, $0b, $0a, $0c
        .byte $0d, $0e, $0d, $0f, $10, $11, $10, $12
        .byte $10, $11, $10, $12, $13, $14, $13, $15
        .byte $10, $11, $10, $12, $16, $16, $16, $17
        .byte $a5
