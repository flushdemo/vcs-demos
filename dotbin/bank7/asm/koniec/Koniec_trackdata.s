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
; Song name: Koniec

.include "../banksetup.inc"

.export koniec_tt_TrackDataStart
.export koniec_tt_InsCtrlTable
.export koniec_tt_InsADIndexes
.export koniec_tt_InsSustainIndexes
.export koniec_tt_InsReleaseIndexes
.export koniec_tt_InsFreqVolTable
.export koniec_tt_PercIndexes
.export koniec_tt_PercFreqTable
.export koniec_tt_PercCtrlVolTable
.export koniec_tt_PatternPtrHi
.export koniec_tt_PatternPtrLo
.export koniec_tt_SequenceTable

.segment RODATA_SEGMENT

; =====================================================================
; TIATracker melodic and percussion instruments, patterns and sequencer
; data.
; =====================================================================
koniec_tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). koniec_tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - koniec_tt_InsCtrlTable: the AUDC value
; - koniec_tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in koniec_tt_InsFreqVolTable
; - koniec_tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - koniec_tt_InsReleaseIndexes: the index of the start of the Release phase
; - koniec_tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
koniec_tt_InsCtrlTable:
        .byte $04, $0c


; Instrument Attack/Decay start indexes into ADSR tables.
koniec_tt_InsADIndexes:
        .byte $00, $00


; Instrument Sustain start indexes into ADSR tables
koniec_tt_InsSustainIndexes:
        .byte $03, $03


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
koniec_tt_InsReleaseIndexes:
        .byte $04, $04


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
koniec_tt_InsFreqVolTable:
; 0+1: Chords
        .byte $8d, $8a, $87, $84, $00, $80, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - koniec_tt_PercIndexes: The index of the first percussion frame as defined
;       in koniec_tt_PercFreqTable and koniec_tt_PercCtrlVolTable
; - koniec_tt_PercFreqTable: The AUDF frequency value
; - koniec_tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in koniec_tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
koniec_tt_PercIndexes:
        .byte $01


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; KONIEC_TT_USE_OVERLAY)
koniec_tt_PercFreqTable:
; 0: Snare
        .byte $04, $09, $0b, $0d, $0f, $11, $13, $15
        .byte $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
koniec_tt_PercCtrlVolTable:
; 0: Snare
        .byte $8e, $8d, $8c, $8b, $8a, $88, $85, $80
        .byte $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - koniec_tt_PatternX (X=0, 1, ...): Pattern definitions
; - koniec_tt_PatternPtrLo/Hi: Pointers to the koniec_tt_PatternX tables, serving
;       as index values
; - koniec_tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into koniec_tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       koniec_tt_cur_pat_index_c0/1 hold an index into koniec_tt_SequenceTable for
;       each channel.
;
; So koniec_tt_SequenceTable holds indexes into koniec_tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (koniec_tt_PatternX) in which the notes
; to play are specified.
; =====================================================================

; ---------------------------------------------------------------------
; Pattern definitions, one table per pattern. koniec_tt_cur_note_index_c0/1
; hold the index values into these tables for the current pattern
; played in channel 0 and 1.
;
; A pattern is a sequence of notes (one byte per note) ending with a 0.
; A note can be either:
; - Pause: Put melodic instrument into release. Must only follow a
;       melodic instrument.
; - Hold: Continue to play last note (or silence). Default "empty" note.
; - Slide (needs KONIEC_TT_USE_SLIDE): Adjust frequency of last melodic note
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
;       - [1..15]: Slide -7..+7 (needs KONIEC_TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------

; mel0
koniec_tt_pattern0:
        .byte $3f, $08, $3f, $08, $2f, $08, $3f, $08
        .byte $3f, $08, $2f, $08, $3f, $08, $3f, $08
        .byte $31, $08, $3f, $08, $3f, $08, $32, $08
        .byte $3f, $08, $3f, $08, $31, $08, $4b, $08
        .byte $3f, $08, $3f, $08, $2f, $08, $3f, $08
        .byte $3f, $08, $2f, $08, $3f, $08, $3f, $08
        .byte $31, $08, $3f, $08, $3f, $08, $32, $08
        .byte $3f, $08, $3f, $08, $31, $08, $2f, $08
        .byte $00

; mel1
koniec_tt_pattern1:
        .byte $3f, $08, $4b, $08, $3f, $08, $3a, $08
        .byte $3f, $08, $3a, $08, $37, $08, $34, $08
        .byte $08, $08, $08, $08, $34, $08, $08, $08
        .byte $34, $08, $34, $08, $08, $08, $08, $08
        .byte $31, $08, $31, $08, $08, $08, $31, $08
        .byte $08, $08, $08, $08, $2f, $08, $37, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $3a, $08, $37, $08, $08, $08, $08, $08
        .byte $00

; mel2
koniec_tt_pattern2:
        .byte $37, $08, $08, $08, $37, $08, $08, $08
        .byte $37, $08, $08, $08, $3a, $08, $37, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $3a, $08, $37, $08, $08, $08, $08, $08
        .byte $3a, $08, $08, $08, $3a, $08, $08, $08
        .byte $3f, $08, $3a, $08, $08, $08, $3a, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $00

; mel3
koniec_tt_pattern3:
        .byte $31, $08, $2f, $08, $3a, $08, $3f, $08
        .byte $08, $08, $08, $08, $4b, $08, $3f, $08
        .byte $08, $08, $08, $08, $08, $08, $3f, $08
        .byte $3a, $08, $08, $08, $37, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $08, $08
        .byte $34, $08, $08, $08, $3a, $08, $3f, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $00

; mel4
koniec_tt_pattern4:
        .byte $31, $08, $2f, $08, $3a, $08, $3f, $08
        .byte $08, $08, $08, $08, $4b, $08, $3f, $08
        .byte $08, $08, $08, $08, $08, $08, $3f, $08
        .byte $3a, $08, $08, $08, $37, $08, $08, $08
        .byte $34, $08, $08, $08, $34, $08, $08, $08
        .byte $34, $08, $08, $08, $31, $08, $34, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $3a, $08, $3f, $08, $4b, $08
        .byte $00

; bassIntro1
koniec_tt_pattern5:
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $5b, $08, $57, $08
        .byte $00

; bassIntro2
koniec_tt_pattern6:
        .byte $54, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $57, $08
        .byte $54, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $08, $08
        .byte $08, $08, $08, $08, $08, $08, $57, $08
        .byte $00

; bass0
koniec_tt_pattern7:
        .byte $54, $08, $54, $08, $54, $08, $54, $08
        .byte $54, $08, $54, $08, $54, $08, $54, $08
        .byte $54, $08, $54, $08, $54, $08, $54, $08
        .byte $54, $08, $54, $08, $54, $08, $54, $08
        .byte $57, $08, $57, $08, $57, $08, $57, $08
        .byte $57, $08, $57, $08, $57, $08, $57, $08
        .byte $57, $08, $57, $08, $57, $08, $57, $08
        .byte $57, $08, $57, $08, $57, $08, $57, $08
        .byte $00

; bass1
koniec_tt_pattern8:
        .byte $58, $08, $58, $08, $58, $08, $58, $08
        .byte $58, $08, $58, $08, $58, $08, $58, $08
        .byte $58, $08, $58, $08, $58, $08, $58, $08
        .byte $58, $08, $58, $08, $58, $08, $58, $08
        .byte $57, $08, $57, $08, $57, $08, $57, $08
        .byte $57, $08, $57, $08, $57, $08, $57, $08
        .byte $57, $08, $57, $08, $57, $08, $5b, $08
        .byte $57, $08, $5b, $08, $54, $08, $51, $08
        .byte $00

; bass+dr0
koniec_tt_pattern9:
        .byte $54, $08, $54, $08, $54, $08, $54, $08
        .byte $11, $08, $54, $08, $54, $08, $54, $08
        .byte $54, $08, $54, $08, $54, $08, $54, $08
        .byte $11, $08, $54, $08, $54, $08, $54, $08
        .byte $57, $08, $57, $08, $57, $08, $57, $08
        .byte $11, $08, $57, $08, $57, $08, $57, $08
        .byte $57, $08, $57, $08, $57, $08, $57, $08
        .byte $11, $08, $57, $08, $11, $08, $57, $08
        .byte $00

; bass+dr1
koniec_tt_pattern10:
        .byte $58, $08, $58, $08, $58, $08, $58, $08
        .byte $11, $08, $58, $08, $58, $08, $58, $08
        .byte $58, $08, $58, $08, $58, $08, $58, $08
        .byte $11, $08, $58, $08, $58, $08, $58, $08
        .byte $57, $08, $57, $08, $57, $08, $57, $08
        .byte $11, $08, $57, $08, $57, $08, $57, $08
        .byte $57, $08, $57, $08, $57, $08, $5b, $08
        .byte $11, $08, $5b, $08, $11, $08, $11, $08
        .byte $00



; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
koniec_tt_PatternPtrLo:
        .byte <koniec_tt_pattern0, <koniec_tt_pattern1, <koniec_tt_pattern2, <koniec_tt_pattern3
        .byte <koniec_tt_pattern4, <koniec_tt_pattern5, <koniec_tt_pattern6, <koniec_tt_pattern7
        .byte <koniec_tt_pattern8, <koniec_tt_pattern9, <koniec_tt_pattern10
koniec_tt_PatternPtrHi:
        .byte >koniec_tt_pattern0, >koniec_tt_pattern1, >koniec_tt_pattern2, >koniec_tt_pattern3
        .byte >koniec_tt_pattern4, >koniec_tt_pattern5, >koniec_tt_pattern6, >koniec_tt_pattern7
        .byte >koniec_tt_pattern8, >koniec_tt_pattern9, >koniec_tt_pattern10        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; koniec_tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. koniec_tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If KONIEC_TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
koniec_tt_SequenceTable:
        ; ---------- Channel 0 ----------
        .byte $00, $00, $00, $00, $00, $00, $01, $02
        .byte $01, $02, $03, $04, $03, $04, $00, $00
        .byte $00, $00, $80

        
        ; ---------- Channel 1 ----------
        .byte $05, $06, $07, $08, $09, $0a, $09, $0a
        .byte $09, $0a, $09, $0a, $09, $0a, $09, $0a
        .byte $09, $0a, $93
