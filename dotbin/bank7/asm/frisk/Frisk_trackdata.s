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

; Song author: 
; Song name: 

.include "../banksetup.inc"

.export frisk_tt_TrackDataStart
.export frisk_tt_InsCtrlTable
.export frisk_tt_InsADIndexes
.export frisk_tt_InsSustainIndexes
.export frisk_tt_InsReleaseIndexes
.export frisk_tt_InsFreqVolTable
.export frisk_tt_PercIndexes
.export frisk_tt_PercFreqTable
.export frisk_tt_PercCtrlVolTable
.export frisk_tt_PatternPtrHi
.export frisk_tt_PatternPtrLo
.export frisk_tt_SequenceTable

.segment RODATA_SEGMENT

; =====================================================================
; TIATracker melodic and percussion instruments, patterns and sequencer
; data.
; =====================================================================
frisk_tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). frisk_tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - frisk_tt_InsCtrlTable: the AUDC value
; - frisk_tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in frisk_tt_InsFreqVolTable
; - frisk_tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - frisk_tt_InsReleaseIndexes: the index of the start of the Release phase
; - frisk_tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
frisk_tt_InsCtrlTable:
        .byte $06, $04, $0c, $07


; Instrument Attack/Decay start indexes into ADSR tables.
frisk_tt_InsADIndexes:
        .byte $00, $0a, $0a, $12


; Instrument Sustain start indexes into ADSR tables
frisk_tt_InsSustainIndexes:
        .byte $06, $0d, $0d, $18


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
frisk_tt_InsReleaseIndexes:
        .byte $07, $0f, $0f, $19


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
frisk_tt_InsFreqVolTable:
; 0: bassline
        .byte $8f, $8f, $8f, $8f, $8f, $8f, $80, $00
        .byte $80, $00
; 1+2: Pizzicato bass
        .byte $87, $8a, $8c, $8d, $7d, $00, $80, $00
; 3: Electronic Guitar
        .byte $8a, $8a, $88, $86, $84, $82, $80, $00
        .byte $80, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - frisk_tt_PercIndexes: The index of the first percussion frame as defined
;       in frisk_tt_PercFreqTable and frisk_tt_PercCtrlVolTable
; - frisk_tt_PercFreqTable: The AUDF frequency value
; - frisk_tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in frisk_tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
frisk_tt_PercIndexes:
        .byte $01, $04


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; FRISK_TT_USE_OVERLAY)
frisk_tt_PercFreqTable:
; 0: Hat
        .byte $02, $02, $00
; 1: Snare
        .byte $05, $09, $08, $09, $0b, $0e, $12, $15
        .byte $17, $19, $1c, $1e, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
frisk_tt_PercCtrlVolTable:
; 0: Hat
        .byte $84, $84, $00
; 1: Snare
        .byte $8f, $8f, $6f, $8e, $8d, $8c, $8b, $8a
        .byte $88, $86, $83, $80, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - frisk_tt_PatternX (X=0, 1, ...): Pattern definitions
; - frisk_tt_PatternPtrLo/Hi: Pointers to the frisk_tt_PatternX tables, serving
;       as index values
; - frisk_tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into frisk_tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       _tt_cur_pat_index_c0/1 hold an index into frisk_tt_SequenceTable for
;       each channel.
;
; So frisk_tt_SequenceTable holds indexes into frisk_tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (frisk_tt_PatternX) in which the notes
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
; - Slide (needs FRISK_TT_USE_SLIDE): Adjust frequency of last melodic note
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
;       - [1..15]: Slide -7..+7 (needs FRISK_TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------

; bass0
frisk_tt_pattern0:
        .byte $31, $10, $31, $08, $08, $08, $08, $08
        .byte $28, $08, $08, $08, $08, $08, $31, $08
        .byte $28, $08, $31, $08, $08, $08, $28, $08
        .byte $08, $08, $31, $08, $28, $08, $08, $08
        .byte $2e, $10, $2e, $08, $08, $08, $08, $08
        .byte $29, $08, $08, $08, $08, $08, $2e, $08
        .byte $29, $08, $2e, $08, $08, $08, $29, $08
        .byte $08, $08, $2e, $08, $29, $08, $28, $08
        .byte $00

; bass1
frisk_tt_pattern1:
        .byte $33, $10, $33, $08, $08, $08, $08, $08
        .byte $29, $08, $08, $08, $08, $08, $33, $08
        .byte $29, $08, $33, $08, $08, $08, $29, $08
        .byte $08, $08, $33, $08, $29, $08, $08, $08
        .byte $33, $10, $33, $08, $08, $08, $08, $08
        .byte $29, $08, $08, $08, $08, $08, $33, $08
        .byte $29, $08, $33, $08, $08, $08, $29, $08
        .byte $08, $08, $2b, $08, $29, $08, $28, $08
        .byte $00

; bass+drum0
frisk_tt_pattern2:
        .byte $31, $10, $31, $08, $08, $08, $11, $08
        .byte $28, $08, $08, $08, $11, $08, $31, $08
        .byte $28, $08, $31, $08, $08, $08, $28, $08
        .byte $08, $08, $31, $08, $28, $08, $11, $08
        .byte $2e, $10, $2e, $08, $08, $08, $11, $08
        .byte $29, $08, $11, $08, $11, $08, $2e, $08
        .byte $29, $08, $2e, $08, $08, $08, $29, $08
        .byte $08, $08, $2e, $08, $29, $08, $28, $08
        .byte $00

; bass+drum1
frisk_tt_pattern3:
        .byte $33, $10, $33, $08, $08, $08, $11, $08
        .byte $29, $08, $08, $08, $11, $08, $33, $08
        .byte $29, $08, $33, $08, $08, $08, $29, $08
        .byte $08, $08, $33, $08, $29, $08, $11, $08
        .byte $33, $10, $33, $08, $08, $08, $11, $08
        .byte $29, $08, $08, $08, $11, $08, $33, $08
        .byte $29, $08, $33, $08, $08, $08, $29, $08
        .byte $08, $08, $2b, $08, $29, $08, $28, $08
        .byte $00

; bass+drum2
frisk_tt_pattern4:
        .byte $31, $10, $31, $08, $11, $08, $11, $08
        .byte $28, $08, $11, $08, $11, $08, $31, $08
        .byte $28, $08, $31, $08, $11, $08, $28, $08
        .byte $08, $08, $31, $08, $28, $08, $11, $08
        .byte $2e, $10, $2e, $08, $11, $08, $11, $08
        .byte $29, $08, $11, $08, $11, $08, $2e, $08
        .byte $29, $08, $2e, $08, $11, $08, $29, $08
        .byte $08, $08, $2e, $08, $29, $08, $28, $08
        .byte $00

; bass+drum3
frisk_tt_pattern5:
        .byte $33, $10, $33, $08, $11, $08, $11, $08
        .byte $29, $08, $11, $08, $11, $08, $33, $08
        .byte $29, $08, $33, $08, $11, $08, $29, $08
        .byte $08, $08, $33, $08, $29, $08, $11, $08
        .byte $33, $10, $33, $08, $11, $08, $11, $08
        .byte $29, $08, $11, $08, $11, $08, $33, $08
        .byte $29, $08, $33, $08, $11, $08, $29, $08
        .byte $08, $08, $2b, $08, $29, $08, $28, $08
        .byte $00

; drum+mel0
frisk_tt_pattern6:
        .byte $11, $51, $08, $08, $11, $4e, $11, $51
        .byte $08, $08, $11, $53, $11, $51, $08, $08
        .byte $11, $4e, $11, $51, $11, $53, $08, $08
        .byte $08, $08, $11, $57, $11, $53, $08, $08
        .byte $11, $51, $08, $08, $11, $4e, $11, $51
        .byte $08, $08, $11, $53, $11, $51, $08, $08
        .byte $11, $4e, $11, $51, $11, $53, $08, $08
        .byte $08, $08, $11, $51, $11, $4e, $08, $08
        .byte $00

; drum+mel1
frisk_tt_pattern7:
        .byte $11, $51, $08, $08, $11, $4e, $11, $51
        .byte $08, $08, $11, $53, $11, $51, $08, $08
        .byte $11, $4e, $11, $51, $11, $53, $08, $08
        .byte $08, $08, $11, $57, $11, $53, $08, $08
        .byte $11, $51, $08, $08, $11, $4e, $11, $51
        .byte $08, $08, $11, $53, $11, $51, $08, $08
        .byte $11, $4e, $11, $51, $11, $53, $08, $08
        .byte $08, $08, $11, $51, $11, $53, $08, $08
        .byte $00

; drum0
frisk_tt_pattern8:
        .byte $11, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $11, $08, $11, $08, $11, $08
        .byte $11, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $11, $08, $11, $08, $11, $08
        .byte $11, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $11, $08, $11, $08, $11, $08
        .byte $11, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $11, $08, $11, $08, $11, $08
        .byte $00

; drum+mel0
frisk_tt_pattern9:
        .byte $91, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $91, $08, $91, $08, $11, $08
        .byte $91, $08, $11, $08, $11, $08, $91, $08
        .byte $12, $08, $11, $08, $8e, $08, $11, $08
        .byte $91, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $91, $08, $91, $08, $11, $08
        .byte $8e, $08, $11, $08, $11, $08, $8f, $08
        .byte $12, $08, $11, $08, $94, $08, $11, $08
        .byte $00

; drum+mel1
frisk_tt_pattern10:
        .byte $91, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $91, $08, $91, $08, $11, $08
        .byte $91, $08, $11, $08, $11, $08, $91, $08
        .byte $12, $08, $11, $08, $8e, $08, $11, $08
        .byte $8b, $08, $11, $08, $89, $08, $88, $08
        .byte $12, $08, $11, $08, $88, $08, $89, $08
        .byte $11, $08, $11, $08, $8b, $08, $8e, $08
        .byte $12, $08, $11, $08, $8b, $08, $12, $08
        .byte $00

; drum+mel3
frisk_tt_pattern11:
        .byte $6b, $08, $11, $08, $11, $08, $5d, $08
        .byte $12, $08, $11, $08, $53, $08, $11, $08
        .byte $51, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $51, $08, $53, $08, $51, $08
        .byte $53, $08, $11, $08, $11, $08, $57, $08
        .byte $12, $08, $5a, $08, $57, $08, $11, $08
        .byte $11, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $57, $08, $53, $08, $51, $08
        .byte $00

; drum+mel4
frisk_tt_pattern12:
        .byte $6b, $08, $11, $08, $11, $08, $5d, $08
        .byte $12, $08, $11, $08, $53, $08, $11, $08
        .byte $51, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $51, $08, $53, $08, $51, $08
        .byte $4e, $08, $11, $08, $11, $08, $4f, $08
        .byte $12, $08, $11, $08, $53, $08, $51, $08
        .byte $11, $08, $11, $08, $11, $08, $11, $08
        .byte $12, $08, $51, $08, $4e, $08, $51, $08
        .byte $00

; drum+mel5
frisk_tt_pattern13:
        .byte $51, $08, $11, $08, $4e, $08, $51, $08
        .byte $12, $08, $53, $08, $51, $08, $11, $08
        .byte $4e, $08, $51, $08, $53, $08, $11, $08
        .byte $12, $08, $57, $08, $53, $08, $11, $08
        .byte $51, $08, $11, $08, $4e, $08, $51, $08
        .byte $12, $08, $53, $08, $51, $08, $11, $08
        .byte $4e, $08, $51, $08, $53, $08, $11, $08
        .byte $12, $08, $51, $08, $4e, $08, $11, $08
        .byte $00

; drum+mel6
frisk_tt_pattern14:
        .byte $51, $08, $11, $08, $4e, $08, $51, $08
        .byte $12, $08, $53, $08, $51, $08, $11, $08
        .byte $4e, $08, $51, $08, $53, $08, $11, $08
        .byte $12, $08, $57, $08, $53, $08, $11, $08
        .byte $51, $08, $11, $08, $4e, $08, $51, $08
        .byte $12, $08, $53, $08, $51, $08, $11, $08
        .byte $4e, $08, $51, $08, $53, $08, $11, $08
        .byte $12, $08, $51, $08, $53, $08, $11, $08
        .byte $00




; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
frisk_tt_PatternPtrLo:
        .byte <frisk_tt_pattern0, <frisk_tt_pattern1, <frisk_tt_pattern2, <frisk_tt_pattern3
        .byte <frisk_tt_pattern4, <frisk_tt_pattern5, <frisk_tt_pattern6, <frisk_tt_pattern7
        .byte <frisk_tt_pattern8, <frisk_tt_pattern9, <frisk_tt_pattern10, <frisk_tt_pattern11
        .byte <frisk_tt_pattern12, <frisk_tt_pattern13, <frisk_tt_pattern14
frisk_tt_PatternPtrHi:
        .byte >frisk_tt_pattern0, >frisk_tt_pattern1, >frisk_tt_pattern2, >frisk_tt_pattern3
        .byte >frisk_tt_pattern4, >frisk_tt_pattern5, >frisk_tt_pattern6, >frisk_tt_pattern7
        .byte >frisk_tt_pattern8, >frisk_tt_pattern9, >frisk_tt_pattern10, >frisk_tt_pattern11
        .byte >frisk_tt_pattern12, >frisk_tt_pattern13, >frisk_tt_pattern14        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; frisk_tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. _tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If FRISK_TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
frisk_tt_SequenceTable:
        ; ---------- Channel 0 ----------
        .byte $00, $01, $00, $01, $00, $01, $00, $01
        .byte $02, $03, $02, $03, $04, $05, $04, $05
        .byte $06, $07, $80

        
        ; ---------- Channel 1 ----------
        .byte $08, $08, $08, $08, $09, $0a, $09, $0a
        .byte $0b, $0c, $0b, $0c, $0d, $0e, $0d, $0e
        .byte $0d, $0e, $93
