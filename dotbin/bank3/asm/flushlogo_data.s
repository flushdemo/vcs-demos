.include "banksetup.inc"

;;; 41 lines (1 blank - 1 top - 1 bottom - 38 data lines)
;;; Color of logo top may be $d0 or $d4
;;; Color of logo bottom is $72

;;; 64 lines display zone

.export _flushlogo_bg, _flushlogo_bg_light, _flushlogo_col
.export _flushlogo_pf0, _flushlogo_pf1, _flushlogo_pf2, _flushlogo_pf3, _flushlogo_pf4, _flushlogo_pf5

.segment RODATA_SEGMENT

_flushlogo_col:
.byte $00, $d4, $72, $d8, $d6, $d6, $d6, $d6, $d6, $b8, $d6, $b8, $d6, $b8, $b8, $b8, $b8, $9a, $b8, $9a, $b8, $9a, $9a, $9a, $9a, $7c, $9a, $7c, $9a, $7c, $7c, $7c, $7c, $5e, $7c, $5e, $7c, $5e, $5e, $5e, $ee

_flushlogo_pf0:
.byte $00, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80

_flushlogo_pf1:
.byte $00, $fb, $83, $fb, $fb, $fb, $fb, $fb, $fb, $fb, $fb, $1b, $1b, $1b, $83, $83, $83, $83, $fb, $fb, $fb, $fb, $fb, $fb, $fb, $fb, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83, $83

_flushlogo_pf2:
.byte $00, $60, $ef, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $6c, $6c, $6c, $ef, $ef, $ef, $ef, $ef, $ef, $ef, $ef

_flushlogo_pf3:
.byte $00, $60, $70, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $70, $70, $70, $70, $70, $70, $70, $70

_flushlogo_pf4:
.byte $00, $fd, $fd, $fd, $fd, $fd, $fd, $fd, $fd, $fd, $fd, $0d, $0d, $0d, $c1, $c1, $c1, $c1, $fd, $fd, $fd, $fd, $fd, $fd, $fd, $fd, $0d, $0d, $0d, $0d, $cd, $cd, $cd, $fd, $fd, $fd, $fd, $fd, $fd, $fd, $fd

_flushlogo_pf5:
.byte $00, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $1f, $1f, $1f, $1f, $1f, $1f, $1f, $1f, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19

pre_bg:
.byte $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0
_flushlogo_bg:
.byte $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0
.byte $b0, $b0, $b0, $b0, $b0, $b0, $b0, $c0, $b0, $b0, $c0, $b0, $a0, $c0, $a0, $a0, $82, $a0, $82, $66, $66, $82, $a0, $82, $a0, $a0, $c0, $a0, $b0, $c0, $b0, $b0, $c0, $b0, $b0, $b0, $b0, $b0
.byte $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0
post_bg:
.byte $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0

pre_bg_light:
.byte $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4
_flushlogo_bg_light:
.byte $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4
.byte $b4, $b4, $b4, $b4, $b4, $b4, $b4, $c0, $b4, $b4, $c0, $b4, $a0, $c0, $a0, $a0, $82, $a0, $82, $66, $66, $82, $a0, $82, $a0, $a0, $c0, $a0, $b4, $c0, $b4, $b4, $c0, $b4, $b4, $b4, $b4, $b4
.byte $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4
post_bg_light:
.byte $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4
