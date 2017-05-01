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

; =====================================================================
; Flags
; =====================================================================

TT_GLOBAL_SPEED = 1
; duration (number of TV frames) of a note
TT_SPEED                = 3
; duration of odd frames (needs TT_USE_FUNKTEMPO)
TT_ODD_SPEED            = 3

; 1: Overlay percussion, +40 bytes
TT_USE_OVERLAY          = 0
; 1: Melodic instrument slide, +11 bytes
TT_USE_SLIDE            = 1
; 1: Goto pattern, +8 bytes
TT_USE_GOTO             = 1
; 1: Odd/even rows have different SPEED values, +7 bytes
TT_USE_FUNKTEMPO        = 0
; If the very first notes played on each channel are not PAUSE, HOLD or
; SLIDE, i.e. if they start with an instrument or percussion, then set
; this flag to 0 to save 2 bytes.
; 0: +2 bytes
TT_STARTS_WITH_NOTES    = 1

; More constants from trackdata
TT_FREQ_MASK    = %00011111
TT_INS_HOLD     = 8
TT_INS_PAUSE    = 16
TT_FIRST_PERC   = 17
