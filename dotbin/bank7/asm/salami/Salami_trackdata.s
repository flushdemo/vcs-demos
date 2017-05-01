; TIATracker music player
; Copyright 2016 Andre "Kylearan" Wichmann
; Website: https://bitbucket.org/kylearan/tiatracker
; Email: andre.wichmann@gmx.de
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

; Song author: Glafouk
; Song name: Salami

.include "../banksetup.inc"

.export salami_tt_TrackDataStart
.export salami_tt_InsCtrlTable
.export salami_tt_InsADIndexes
.export salami_tt_InsSustainIndexes
.export salami_tt_InsReleaseIndexes
.export salami_tt_InsFreqVolTable
.export salami_tt_PercIndexes
.export salami_tt_PercFreqTable
.export salami_tt_PercCtrlVolTable
.export salami_tt_PatternPtrHi
.export salami_tt_PatternPtrLo
.export salami_tt_SequenceTable

.segment RODATA_SEGMENT

; =====================================================================
; TIATracker melodic and percussion instruments, patterns and sequencer
; data.
; =====================================================================
salami_tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - tt_InsCtrlTable: the AUDC value
; - tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in tt_InsFreqVolTable
; - tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - tt_InsReleaseIndexes: the index of the start of the Release phase
; - tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
salami_tt_InsCtrlTable:
        .byte $06, $04, $0c


; Instrument Attack/Decay start indexes into ADSR tables.
salami_tt_InsADIndexes:
        .byte $00, $08, $08


; Instrument Sustain start indexes into ADSR tables
salami_tt_InsSustainIndexes:
        .byte $04, $0c, $0c


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
salami_tt_InsReleaseIndexes:
        .byte $05, $0d, $0d


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
salami_tt_InsFreqVolTable:
; 0: bassline
        .byte $8f, $8f, $8f, $8f, $86, $00, $80, $00
; 1+2: Chords
        .byte $8c, $7a, $8b, $8c, $80, $00, $80, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - salami_tt_PercIndexes: The index of the first percussion frame as defined
;       in salami_tt_PercFreqTable and salami_tt_PercCtrlVolTable
; - salami_tt_PercFreqTable: The AUDF frequency value
; - salami_tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in salami_tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
salami_tt_PercIndexes:
        .byte $01, $05, $14


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; SALAMI_TT_USE_OVERLAY)
salami_tt_PercFreqTable:
; 0: Hat
        .byte $02, $02, $02, $00
; 1: Kick
        .byte $04, $01, $03, $03, $04, $05, $06, $07
        .byte $08, $09, $0a, $0b, $0c, $0d, $00
; 2: Snare
        .byte $07, $0d, $0e, $10, $14, $14, $15, $18
        .byte $18, $19, $1a, $1b, $1e, $1f, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
salami_tt_PercCtrlVolTable:
; 0: Hat
        .byte $88, $86, $84, $00
; 1: Kick
        .byte $ef, $ee, $ee, $eb, $e9, $e8, $e8, $e6
        .byte $e6, $e6, $e4, $e4, $e2, $e2, $00
; 2: Snare
        .byte $8e, $8d, $8d, $8c, $8b, $8a, $88, $88
        .byte $87, $86, $84, $82, $81, $80, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - salami_tt_PatternX (X=0, 1, ...): Pattern definitions
; - salami_tt_PatternPtrLo/Hi: Pointers to the salami_tt_PatternX tables, serving
;       as index values
; - salami_tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into salami_tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       salami_tt_cur_pat_index_c0/1 hold an index into salami_tt_SequenceTable for
;       each channel.
;
; So salami_tt_SequenceTable holds indexes into salami_tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (salami_tt_PatternX) in which the notes
; to play are specified.
; =====================================================================

; ---------------------------------------------------------------------
; Pattern definitions, one table per pattern. salami_tt_cur_note_index_c0/1
; hold the index values into these tables for the current pattern
; played in channel 0 and 1.
;
; A pattern is a sequence of notes (one byte per note) ending with a 0.
; A note can be either:
; - Pause: Put melodic instrument into release. Must only follow a
;       melodic instrument.
; - Hold: Continue to play last note (or silence). Default "empty" note.
; - Slide (needs SALAMI_TT_USE_SLIDE): Adjust frequency of last melodic note
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
;       - [1..15]: Slide -7..+7 (needs SALAMI_TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------

; jointure
salami_tt_pattern0:
        .byte $38, $08, $08, $08, $08, $08, $08, $08
        .byte $09, $08, $08, $08, $09, $08, $08, $08
        .byte $09, $08, $08, $08, $09, $08, $08, $08
        .byte $09, $08, $08, $08, $08, $08, $08, $08
        .byte $6c, $53, $48, $49, $08, $08, $08, $08
        .byte $4e, $08, $4e, $08, $4c, $08, $08, $08
        .byte $4e, $4e, $08, $08, $08, $08, $08, $08
        .byte $4a, $4a, $08, $08, $49, $49, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $00

; bass0
salami_tt_pattern1:
        .byte $30, $08, $30, $08, $08, $08, $08, $08
        .byte $30, $08, $08, $08, $08, $08, $30, $08
        .byte $08, $08, $08, $08, $30, $08, $08, $08
        .byte $08, $08, $32, $08, $32, $08, $32, $08
        .byte $2d, $08, $2d, $08, $08, $08, $08, $08
        .byte $2d, $08, $08, $08, $08, $08, $2d, $08
        .byte $08, $08, $08, $08, $2d, $08, $08, $08
        .byte $08, $08, $2d, $08, $2d, $08, $2c, $08
        .byte $00

; bass1
salami_tt_pattern2:
        .byte $34, $08, $34, $08, $08, $08, $08, $08
        .byte $34, $08, $08, $08, $08, $08, $34, $08
        .byte $08, $08, $08, $08, $34, $08, $08, $08
        .byte $08, $08, $34, $08, $34, $08, $34, $08
        .byte $2f, $08, $2f, $08, $08, $08, $08, $08
        .byte $2f, $08, $08, $08, $08, $08, $2f, $08
        .byte $08, $08, $08, $08, $32, $08, $2f, $08
        .byte $08, $08, $2d, $08, $32, $08, $08, $08
        .byte $00

; bass+mel0
salami_tt_pattern3:
        .byte $30, $08, $30, $08, $71, $08, $08, $08
        .byte $30, $08, $08, $08, $78, $08, $30, $08
        .byte $08, $08, $08, $08, $30, $08, $75, $08
        .byte $71, $08, $32, $08, $32, $08, $32, $08
        .byte $2d, $08, $2d, $08, $71, $08, $08, $08
        .byte $2d, $08, $6b, $08, $6e, $08, $2d, $08
        .byte $71, $08, $6f, $08, $2d, $08, $2f, $08
        .byte $08, $08, $2d, $08, $2d, $08, $2c, $08
        .byte $00

; bass+mel1
salami_tt_pattern4:
        .byte $34, $08, $34, $08, $71, $08, $08, $08
        .byte $34, $08, $08, $08, $78, $08, $34, $08
        .byte $08, $08, $08, $08, $34, $08, $75, $08
        .byte $71, $08, $34, $08, $34, $08, $34, $08
        .byte $2f, $08, $2f, $08, $71, $08, $08, $08
        .byte $2f, $08, $6b, $08, $6e, $08, $2f, $08
        .byte $71, $08, $6f, $08, $32, $08, $2f, $08
        .byte $08, $08, $2d, $08, $32, $08, $08, $08
        .byte $00

; bass+mel2
salami_tt_pattern5:
        .byte $30, $08, $30, $08, $5f, $08, $08, $08
        .byte $30, $08, $6b, $08, $5f, $08, $30, $08
        .byte $51, $08, $5a, $08, $30, $08, $08, $08
        .byte $08, $08, $5a, $08, $57, $08, $32, $08
        .byte $55, $08, $2d, $08, $55, $08, $2d, $08
        .byte $55, $08, $08, $08, $57, $08, $2d, $08
        .byte $08, $08, $08, $08, $2d, $08, $08, $08
        .byte $08, $08, $2d, $08, $2d, $08, $2c, $08
        .byte $00

; bass+mel3
salami_tt_pattern6:
        .byte $34, $08, $34, $08, $51, $08, $08, $08
        .byte $34, $08, $55, $08, $51, $08, $34, $08
        .byte $08, $08, $08, $08, $34, $08, $08, $08
        .byte $51, $08, $34, $08, $34, $08, $34, $08
        .byte $2f, $08, $2f, $08, $08, $08, $5a, $08
        .byte $57, $08, $08, $08, $55, $08, $2f, $08
        .byte $08, $08, $08, $08, $32, $08, $2f, $08
        .byte $6b, $08, $2d, $08, $32, $08, $08, $08
        .byte $00

; bass+mel4
salami_tt_pattern7:
        .byte $30, $08, $30, $08, $51, $08, $55, $08
        .byte $30, $08, $5a, $08, $4f, $08, $30, $08
        .byte $55, $08, $08, $08, $30, $08, $51, $08
        .byte $4f, $08, $32, $08, $32, $08, $4f, $08
        .byte $2d, $08, $2d, $08, $51, $08, $4f, $08
        .byte $2d, $08, $5a, $08, $57, $08, $2d, $08
        .byte $5f, $08, $6b, $08, $2d, $08, $57, $08
        .byte $08, $08, $2d, $08, $2d, $08, $2c, $08
        .byte $00

; bass+mel5
salami_tt_pattern8:
        .byte $34, $08, $34, $08, $51, $08, $55, $08
        .byte $34, $08, $57, $08, $5a, $08, $34, $08
        .byte $57, $08, $08, $08, $34, $08, $5a, $08
        .byte $57, $08, $34, $08, $34, $08, $55, $08
        .byte $2f, $08, $2f, $08, $55, $08, $55, $08
        .byte $2f, $08, $57, $08, $5a, $08, $2f, $08
        .byte $5f, $08, $6b, $08, $32, $08, $2f, $08
        .byte $5f, $08, $2d, $08, $32, $08, $08, $08
        .byte $00

; mel0
salami_tt_pattern9:
        .byte $74, $08, $74, $08, $71, $08, $08, $08
        .byte $08, $08, $75, $08, $78, $08, $78, $08
        .byte $08, $08, $08, $08, $08, $08, $75, $08
        .byte $71, $08, $75, $08, $08, $08, $08, $08
        .byte $08, $08, $71, $08, $71, $08, $6a, $08
        .byte $08, $08, $6b, $08, $6e, $08, $08, $08
        .byte $71, $08, $6f, $08, $08, $08, $6d, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $00

; mel1
salami_tt_pattern10:
        .byte $74, $08, $74, $08, $71, $08, $08, $08
        .byte $08, $08, $75, $08, $78, $08, $78, $08
        .byte $08, $08, $08, $08, $08, $08, $75, $08
        .byte $71, $08, $75, $08, $08, $08, $08, $08
        .byte $08, $08, $71, $08, $71, $08, $6a, $08
        .byte $08, $08, $6b, $08, $6e, $08, $11, $08
        .byte $71, $08, $6f, $08, $08, $08, $71, $08
        .byte $11, $08, $12, $08, $12, $08, $12, $08
        .byte $00

; jointure2
salami_tt_pattern11:
        .byte $11, $11, $11, $11, $08, $11, $08, $11
        .byte $08, $08, $11, $08, $08, $08, $11, $08
        .byte $08, $08, $08, $11, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $11
        .byte $08, $08, $08, $08, $08, $08, $11, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $00

; blank
salami_tt_pattern12:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $00

; k0
salami_tt_pattern13:
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $12, $08, $08, $08
        .byte $00

; k1
salami_tt_pattern14:
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $11, $11, $11, $11, $11, $08
        .byte $12, $08, $11, $11, $11, $08, $11, $08
        .byte $12, $08, $11, $11, $11, $08, $11, $08
        .byte $00

; k+h0
salami_tt_pattern15:
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $11, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $12, $08, $12, $08
        .byte $00

; k+h1
salami_tt_pattern16:
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $11, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $11, $11, $11, $11, $11, $08
        .byte $00

; k+h+c0
salami_tt_pattern17:
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $11, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $13, $08
        .byte $00

; k+h+c1
salami_tt_pattern18:
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $11, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $11, $11, $11, $11, $13, $08
        .byte $00

; k+h+c+mel0
salami_tt_pattern19:
        .byte $12, $08, $74, $08, $11, $08, $08, $08
        .byte $13, $08, $75, $08, $11, $08, $78, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $75, $08, $11, $08, $11, $08
        .byte $12, $08, $71, $08, $11, $08, $6a, $08
        .byte $13, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $6d, $08
        .byte $13, $08, $08, $08, $11, $08, $13, $08
        .byte $00

; k+h+c+mel1
salami_tt_pattern20:
        .byte $12, $08, $74, $08, $11, $08, $08, $08
        .byte $13, $08, $75, $08, $11, $08, $78, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $75, $08, $11, $08, $11, $08
        .byte $12, $08, $71, $08, $11, $08, $6a, $08
        .byte $13, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $71, $08
        .byte $13, $08, $08, $08, $11, $08, $13, $08
        .byte $00

; k+h+c+mel2
salami_tt_pattern21:
        .byte $12, $08, $5f, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $4f, $08
        .byte $12, $08, $08, $08, $11, $08, $57, $08
        .byte $13, $08, $08, $08, $11, $08, $5a, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $5a, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $55, $08, $51, $08, $13, $08
        .byte $00

; k+h+c+mel3
salami_tt_pattern22:
        .byte $12, $08, $4f, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $4f, $08
        .byte $12, $08, $08, $08, $11, $08, $55, $08
        .byte $13, $08, $55, $08, $11, $08, $57, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $5a, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $5f, $08, $11, $08, $13, $08
        .byte $00

; k+h+c+mel4
salami_tt_pattern23:
        .byte $12, $08, $4f, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $51, $08, $11, $08, $11, $08
        .byte $12, $08, $55, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $5a, $08, $11, $08, $13, $08
        .byte $00

; k+h+c+mel5
salami_tt_pattern24:
        .byte $12, $08, $55, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $08, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $5a, $08, $11, $08, $11, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $08, $08, $11, $08, $57, $08
        .byte $12, $08, $08, $08, $11, $08, $08, $08
        .byte $13, $08, $5a, $08, $11, $08, $13, $08
        .byte $00



; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
salami_tt_PatternPtrLo:
        .byte <salami_tt_pattern0, <salami_tt_pattern1, <salami_tt_pattern2, <salami_tt_pattern3
        .byte <salami_tt_pattern4, <salami_tt_pattern5, <salami_tt_pattern6, <salami_tt_pattern7
        .byte <salami_tt_pattern8, <salami_tt_pattern9, <salami_tt_pattern10, <salami_tt_pattern11
        .byte <salami_tt_pattern12, <salami_tt_pattern13, <salami_tt_pattern14, <salami_tt_pattern15
        .byte <salami_tt_pattern16, <salami_tt_pattern17, <salami_tt_pattern18, <salami_tt_pattern19
        .byte <salami_tt_pattern20, <salami_tt_pattern21, <salami_tt_pattern22, <salami_tt_pattern23
        .byte <salami_tt_pattern24
salami_tt_PatternPtrHi:
        .byte >salami_tt_pattern0, >salami_tt_pattern1, >salami_tt_pattern2, >salami_tt_pattern3
        .byte >salami_tt_pattern4, >salami_tt_pattern5, >salami_tt_pattern6, >salami_tt_pattern7
        .byte >salami_tt_pattern8, >salami_tt_pattern9, >salami_tt_pattern10, >salami_tt_pattern11
        .byte >salami_tt_pattern12, >salami_tt_pattern13, >salami_tt_pattern14, >salami_tt_pattern15
        .byte >salami_tt_pattern16, >salami_tt_pattern17, >salami_tt_pattern18, >salami_tt_pattern19
        .byte >salami_tt_pattern20, >salami_tt_pattern21, >salami_tt_pattern22, >salami_tt_pattern23
        .byte >salami_tt_pattern24        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; salami_tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. salami_tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If SALAMI_TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
salami_tt_SequenceTable:
        ; ---------- Channel 0 ----------
        .byte $00, $01, $02, $01, $02, $01, $02, $01
        .byte $02, $03, $04, $03, $04, $05, $06, $05
        .byte $06, $03, $04, $03, $04, $07, $08, $07
        .byte $08, $09, $0a, $01, $02, $83

        
        ; ---------- Channel 1 ----------
        .byte $0b, $0c, $0c, $0d, $0e, $0f, $10, $11
        .byte $12, $13, $14, $13, $14, $15, $16, $15
        .byte $16, $13, $14, $13, $14, $17, $18, $17
        .byte $18, $11, $12, $0d, $0d, $a3
