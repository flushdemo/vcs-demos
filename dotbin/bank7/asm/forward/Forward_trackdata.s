.include "../banksetup.inc"

.export forward_tt_TrackDataStart
.export forward_tt_InsCtrlTable
.export forward_tt_InsADIndexes
.export forward_tt_InsSustainIndexes
.export forward_tt_InsReleaseIndexes
.export forward_tt_InsFreqVolTable
.export forward_tt_PercIndexes
.export forward_tt_PercFreqTable
.export forward_tt_PercCtrlVolTable
.export forward_tt_PatternPtrHi
.export forward_tt_PatternPtrLo
.export forward_tt_SequenceTable

.segment RODATA_SEGMENT

forward_tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). forward_tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - forward_tt_InsCtrlTable: the AUDC value
; - forward_tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in forward_tt_InsFreqVolTable
; - forward_tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - forward_tt_InsReleaseIndexes: the index of the start of the Release phase
; - forward_tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
forward_tt_InsCtrlTable:
        .byte $04, $0c, $06, $06


; Instrument Attack/Decay start indexes into ADSR tables.
forward_tt_InsADIndexes:
        .byte $00, $00, $06, $14


; Instrument Sustain start indexes into ADSR tables
forward_tt_InsSustainIndexes:
        .byte $02, $02, $10, $22


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
forward_tt_InsReleaseIndexes:
        .byte $03, $03, $11, $23


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
forward_tt_InsFreqVolTable:
; 0+1: Sine
        .byte $8b, $8b, $80, $00, $80, $00
; 2: bassline
        .byte $8f, $8f, $8f, $8f, $8f, $8f, $8f, $8f
        .byte $8f, $8f, $80, $00, $8f, $00
; 3: gabbaKick
        .byte $7f, $0f, $0f, $1e, $4d, $5c, $6a, $78
        .byte $87, $95, $a4, $b3, $c2, $d1, $e0, $00
        .byte $f0, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - forward_tt_PercIndexes: The index of the first percussion frame as defined
;       in forward_tt_PercFreqTable and forward_tt_PercCtrlVolTable
; - forward_tt_PercFreqTable: The AUDF frequency value
; - forward_tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in forward_tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
forward_tt_PercIndexes:
        .byte $01, $0a


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; FORWARD_TT_USE_OVERLAY)
forward_tt_PercFreqTable:
; 0: Snare
        .byte $07, $08, $0a, $0c, $0e, $11, $15, $18
        .byte $00
; 1: Hat
        .byte $00, $00, $00, $01, $00, $00, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
forward_tt_PercCtrlVolTable:
; 0: Snare
        .byte $8e, $8d, $8d, $8c, $8b, $8a, $88, $86
        .byte $00
; 1: Hat
        .byte $8a, $89, $88, $87, $86, $85, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - forward_tt_PatternX (X=0, 1, ...): Pattern definitions
; - forward_tt_PatternPtrLo/Hi: Pointers to the forward_tt_PatternX tables, serving
;       as index values
; - forward_tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into forward_tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       _tt_cur_pat_index_c0/1 hold an index into forward_tt_SequenceTable for
;       each channel.
;
; So forward_tt_SequenceTable holds indexes into forward_tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (forward_tt_PatternX) in which the notes
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
; - Slide (needs FORWARD_TT_USE_SLIDE): Adjust frequency of last melodic note
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
;       - [1..15]: Slide -7..+7 (needs FORWARD_TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------

; mel0
forward_tt_pattern0:
        .byte $5f, $08, $08, $08, $5f, $08, $08, $08
        .byte $08, $08, $08, $08, $5f, $08, $08, $08
        .byte $5d, $10, $5d, $10, $5d, $10, $5d, $10
        .byte $5d, $08, $08, $08, $5d, $08, $08, $08
        .byte $5f, $08, $08, $08, $5f, $08, $08, $08
        .byte $5f, $08, $08, $08, $08, $08, $08, $08
        .byte $5d, $10, $5d, $10, $5d, $10, $5d, $10
        .byte $5d, $08, $08, $08, $5a, $08, $08, $08
        .byte $00

; mel+clap0
forward_tt_pattern1:
        .byte $5f, $08, $08, $08, $5f, $08, $08, $08
        .byte $11, $08, $08, $08, $5f, $08, $08, $08
        .byte $5d, $10, $5d, $10, $5d, $10, $5d, $10
        .byte $11, $08, $08, $08, $5d, $08, $08, $08
        .byte $5f, $08, $08, $08, $5f, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $5d, $10, $5d, $10, $5d, $10, $5d, $10
        .byte $11, $08, $08, $08, $11, $08, $5a, $08
        .byte $00

; bass0
forward_tt_pattern2:
        .byte $78, $08, $08, $08, $78, $08, $10, $08
        .byte $78, $10, $78, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $4e, $08, $4f, $08, $08, $08, $08, $08
        .byte $3f, $08, $08, $08, $08, $08, $4c, $08
        .byte $08, $08, $08, $08, $74, $10, $74, $08
        .byte $00

; bass+hihat0
forward_tt_pattern3:
        .byte $78, $08, $08, $08, $12, $08, $78, $08
        .byte $78, $10, $78, $08, $12, $08, $08, $08
        .byte $08, $08, $08, $08, $12, $08, $08, $08
        .byte $08, $08, $08, $08, $12, $08, $08, $08
        .byte $08, $08, $08, $08, $12, $08, $08, $08
        .byte $4e, $08, $4f, $08, $12, $08, $08, $08
        .byte $3f, $08, $08, $08, $12, $08, $4c, $08
        .byte $08, $08, $08, $08, $12, $08, $74, $08
        .byte $00

; bass+hihat+kick0
forward_tt_pattern4:
        .byte $94, $08, $78, $08, $12, $08, $78, $08
        .byte $94, $08, $78, $08, $12, $08, $08, $08
        .byte $94, $08, $08, $08, $12, $08, $08, $08
        .byte $94, $08, $08, $08, $12, $08, $08, $08
        .byte $94, $08, $08, $08, $12, $08, $08, $08
        .byte $94, $08, $3f, $10, $12, $08, $3d, $10
        .byte $94, $08, $4c, $10, $12, $08, $08, $08
        .byte $94, $08, $4f, $10, $94, $08, $74, $08
        .byte $00

; bass+hihat+kick1
forward_tt_pattern5:
        .byte $94, $08, $78, $08, $12, $08, $78, $08
        .byte $94, $08, $78, $08, $12, $08, $08, $08
        .byte $94, $08, $08, $08, $12, $08, $08, $08
        .byte $94, $08, $08, $08, $12, $08, $08, $08
        .byte $94, $08, $08, $08, $12, $08, $4f, $08
        .byte $94, $08, $4e, $08, $12, $08, $4f, $08
        .byte $94, $08, $3f, $08, $94, $08, $12, $08
        .byte $94, $08, $94, $08, $94, $08, $74, $08
        .byte $00

; kick+bass0
forward_tt_pattern6:
        .byte $94, $08, $08, $08, $78, $08, $08, $08
        .byte $94, $08, $08, $08, $78, $08, $08, $08
        .byte $94, $08, $08, $08, $78, $08, $08, $08
        .byte $94, $08, $08, $08, $78, $08, $08, $08
        .byte $94, $08, $08, $08, $78, $08, $08, $08
        .byte $94, $08, $08, $08, $78, $08, $08, $08
        .byte $94, $08, $08, $08, $7b, $08, $08, $08
        .byte $94, $08, $08, $08, $94, $08, $94, $08
        .byte $00



; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
forward_tt_PatternPtrLo:
        .byte <forward_tt_pattern0, <forward_tt_pattern1, <forward_tt_pattern2, <forward_tt_pattern3
        .byte <forward_tt_pattern4, <forward_tt_pattern5, <forward_tt_pattern6
forward_tt_PatternPtrHi:
        .byte >forward_tt_pattern0, >forward_tt_pattern1, >forward_tt_pattern2, >forward_tt_pattern3
        .byte >forward_tt_pattern4, >forward_tt_pattern5, >forward_tt_pattern6        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; forward_tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. _tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If FORWARD_TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
forward_tt_SequenceTable:
        ; ---------- Channel 0 ----------
        .byte $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $01, $01, $01, $01
        .byte $01, $01, $01, $01, $01, $01, $01, $00
        .byte $80

        
        ; ---------- Channel 1 ----------
        .byte $02, $02, $02, $02, $03, $03, $03, $03
        .byte $04, $05, $04, $05, $04, $05, $04, $05
        .byte $02, $02, $03, $03, $06, $06, $06, $06
        .byte $99
