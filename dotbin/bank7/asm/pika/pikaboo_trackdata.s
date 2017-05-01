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

.include "../banksetup.inc"

.export pika_tt_TrackDataStart
.export pika_tt_InsCtrlTable
.export pika_tt_InsADIndexes
.export pika_tt_InsSustainIndexes
.export pika_tt_InsReleaseIndexes
.export pika_tt_InsFreqVolTable
.export pika_tt_PercIndexes
.export pika_tt_PercFreqTable
.export pika_tt_PercCtrlVolTable
.export pika_tt_PatternPtrHi
.export pika_tt_PatternPtrLo
.export pika_tt_SequenceTable

.segment RODATA_SEGMENT

; Song author: Glafouk
; Song name: Pikaboo

; =====================================================================
; TIATracker melodic and percussion instruments, patterns and sequencer
; data.
; =====================================================================
pika_tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). pika_tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - pika_tt_InsCtrlTable: the AUDC value
; - pika_tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in pika_tt_InsFreqVolTable
; - pika_tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - pika_tt_InsReleaseIndexes: the index of the start of the Release phase
; - pika_tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
pika_tt_InsCtrlTable:
        .byte $06, $07


; Instrument Attack/Decay start indexes into ADSR tables.
pika_tt_InsADIndexes:
        .byte $00, $0a


; Instrument Sustain start indexes into ADSR tables
pika_tt_InsSustainIndexes:
        .byte $06, $10


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
pika_tt_InsReleaseIndexes:
        .byte $07, $11


; AUDVx and AUDFx ADSR envelope values.
; Each .byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one .byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
pika_tt_InsFreqVolTable:
; 0: bassline
        .byte $8f, $8f, $8e, $8c, $88, $84, $80, $00
        .byte $80, $00
; 1: bassline2
        .byte $85, $86, $87, $86, $84, $82, $80, $00
        .byte $80, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - pika_tt_PercIndexes: The index of the first percussion frame as defined
;       in pika_tt_PercFreqTable and pika_tt_PercCtrlVolTable
; - pika_tt_PercFreqTable: The AUDF frequency value
; - pika_tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in pika_tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
pika_tt_PercIndexes:
        .byte $01, $0b, $18


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; PIKA_TT_USE_OVERLAY)
pika_tt_PercFreqTable:
; 0: Snare
        .byte $06, $07, $07, $09, $0b, $0e, $13, $18
        .byte $18, $00
; 1: Kick
        .byte $05, $05, $06, $06, $07, $07, $07, $08
        .byte $0b, $12, $19, $1f, $00
; 2: hit
        .byte $00, $00, $00, $00, $00, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
pika_tt_PercCtrlVolTable:
; 0: Snare
        .byte $8f, $8f, $8e, $8d, $8c, $8b, $8a, $89
        .byte $88, $00
; 1: Kick
        .byte $ef, $ef, $ef, $ef, $ee, $ec, $ea, $e8
        .byte $e6, $e4, $e2, $e0, $00
; 2: hit
        .byte $8f, $8c, $88, $84, $80, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - pika_tt_PatternX (X=0, 1, ...): Pattern definitions
; - pika_tt_PatternPtrLo/Hi: Pointers to the pika_tt_PatternX tables, serving
;       as index values
; - pika_tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into pika_tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       _tt_cur_pat_index_c0/1 hold an index into pika_tt_SequenceTable for
;       each channel.
;
; So pika_tt_SequenceTable holds indexes into pika_tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (pika_tt_PatternX) in which the notes
; to play are specified.
; =====================================================================

; ---------------------------------------------------------------------
; Pattern definitions, one table per pattern. _tt_cur_note_index_c0/1
; hold the index values into these tables for the current pattern
; played in channel 0 and 1.
;
; A pattern is a sequence of notes (one .byte per note) ending with a 0.
; A note can be either:
; - Pause: Put melodic instrument into release. Must only follow a
;       melodic instrument.
; - Hold: Continue to play last note (or silence). Default "empty" note.
; - Slide (needs PIKA_TT_USE_SLIDE): Adjust frequency of last melodic note
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
;       - [1..15]: Slide -7..+7 (needs PIKA_TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------
PIKA_TT_FREQ_MASK    = %00011111
PIKA_TT_INS_HOLD     = 8
PIKA_TT_INS_PAUSE    = 16
PIKA_TT_FIRST_PERC   = 17

; bassline0
pika_tt_pattern0:
        .byte $36, $08, $08, $08, $36, $08, $08, $08
        .byte $08, $08, $36, $08, $08, $08, $36, $08
        .byte $08, $08, $36, $08, $08, $08, $36, $08
        .byte $08, $08, $36, $08, $36, $08, $36, $08
        .byte $32, $08, $32, $08, $08, $08, $32, $08
        .byte $08, $08, $32, $08, $30, $08, $30, $08
        .byte $08, $08, $30, $08, $08, $08, $30, $08
        .byte $08, $08, $39, $08, $39, $08, $08, $08
        .byte $00

; bassline+snare0
pika_tt_pattern1:
        .byte $36, $08, $08, $08, $36, $08, $08, $08
        .byte $11, $08, $36, $08, $08, $08, $36, $08
        .byte $08, $08, $36, $08, $08, $08, $36, $08
        .byte $11, $08, $36, $08, $36, $08, $36, $08
        .byte $32, $08, $32, $08, $08, $08, $32, $08
        .byte $11, $08, $32, $08, $30, $08, $30, $08
        .byte $08, $08, $30, $08, $08, $08, $30, $08
        .byte $11, $08, $39, $08, $39, $08, $08, $08
        .byte $00

; bassline+snare1
pika_tt_pattern2:
        .byte $36, $08, $08, $08, $36, $08, $08, $08
        .byte $11, $08, $36, $08, $08, $08, $36, $08
        .byte $08, $08, $36, $08, $08, $08, $36, $08
        .byte $11, $08, $36, $08, $36, $08, $36, $08
        .byte $32, $08, $32, $08, $08, $08, $32, $08
        .byte $11, $08, $32, $08, $30, $08, $30, $08
        .byte $08, $08, $30, $08, $08, $08, $30, $08
        .byte $11, $08, $39, $08, $08, $08, $11, $08
        .byte $00

; snare0
pika_tt_pattern3:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $11, $08, $08, $08, $08, $08, $11, $08
        .byte $00

; drum0
pika_tt_pattern4:
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $12, $08, $08, $08, $08, $08, $08, $08
        .byte $00

; drum1
pika_tt_pattern5:
        .byte $12, $08, $08, $08, $13, $08, $08, $08
        .byte $12, $08, $08, $08, $13, $08, $08, $08
        .byte $12, $08, $08, $08, $13, $08, $08, $08
        .byte $12, $08, $08, $08, $13, $08, $13, $08
        .byte $12, $08, $08, $08, $13, $08, $08, $08
        .byte $12, $08, $08, $08, $13, $08, $08, $08
        .byte $12, $08, $08, $08, $13, $08, $08, $08
        .byte $12, $08, $08, $08, $13, $08, $13, $08
        .byte $00

; drum+bass0
pika_tt_pattern6:
        .byte $12, $08, $56, $08, $13, $08, $56, $08
        .byte $12, $08, $08, $08, $13, $08, $08, $08
        .byte $12, $08, $56, $08, $13, $08, $56, $08
        .byte $12, $08, $08, $08, $13, $08, $13, $08
        .byte $12, $08, $56, $08, $13, $08, $56, $08
        .byte $12, $08, $08, $08, $13, $08, $08, $08
        .byte $12, $08, $56, $08, $13, $08, $56, $08
        .byte $12, $08, $12, $08, $13, $08, $13, $08
        .byte $00

; drum+bass1
pika_tt_pattern7:
        .byte $12, $08, $56, $08, $13, $08, $56, $08
        .byte $12, $08, $52, $08, $13, $08, $50, $08
        .byte $12, $08, $56, $08, $13, $08, $56, $08
        .byte $12, $08, $56, $08, $13, $08, $13, $08
        .byte $12, $08, $56, $08, $13, $08, $56, $08
        .byte $12, $08, $52, $08, $13, $08, $50, $08
        .byte $12, $08, $56, $08, $13, $08, $56, $08
        .byte $12, $08, $12, $08, $13, $08, $13, $08
        .byte $00




; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
pika_tt_PatternPtrLo:
        .byte <pika_tt_pattern0, <pika_tt_pattern1, <pika_tt_pattern2, <pika_tt_pattern3
        .byte <pika_tt_pattern4, <pika_tt_pattern5, <pika_tt_pattern6, <pika_tt_pattern7

pika_tt_PatternPtrHi:
        .byte >pika_tt_pattern0, >pika_tt_pattern1, >pika_tt_pattern2, >pika_tt_pattern3
        .byte >pika_tt_pattern4, >pika_tt_pattern5, >pika_tt_pattern6, >pika_tt_pattern7
        


; ---------------------------------------------------------------------
; Pattern sequence table. Each .byte is an index into the
; pika_tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next .byte from this table is used to get the address of the next
; pattern to play. _tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If PIKA_TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
pika_tt_SequenceTable:
        ; ---------- Channel 0 ----------
        .byte $00, $00, $00, $00, $01, $02, $01, $02
        .byte $01, $02, $01, $02, $01, $02, $01, $02
        .byte $03, $03, $03, $03, $01, $02, $80

        
        ; ---------- Channel 1 ----------
        .byte $04, $04, $05, $05, $05, $05, $05, $05
        .byte $06, $06, $06, $06, $07, $07, $07, $07
        .byte $07, $06, $07, $06, $06, $06, $97
